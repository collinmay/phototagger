require "sinatra"
require "sinatra/config_file"
require "sinatra/partial"
require "faye/websocket"
require "oauth2"
require "haml"
require "nokogiri"
require "json"
require "sequel"
require "faraday"
require "faraday_middleware"
require "byebug"
require "thread"

USERINFO_SCOPE = "https://www.googleapis.com/auth/userinfo.profile"

register Sinatra::Partial

#begin
#  DB = Sequel.connect(settings.db_path, :test => true)
#  Sequel.extension :migration
#  set :db_error, false
#rescue Sequel::DatabaseConnectionError => e
#  set :db_error, e
#end

#set :oauth2_client, OAuth2::Client.new(settings.google_client_id, settings.google_client_secret, {
#                                         :site => "https://accounts.google.com",
#                                         :authorize_url => "/o/oauth2/auth",
#                                         :token_url => "/o/oauth2/token"
#                                       })

set :setup_lock, Mutex.new
set :setup_step, "step1"
set :sockets_waiting, Array.new
set :server, :thin

register Sinatra::ConfigFile
config_file "./config.yml"
set :oauth2_client, OAuth2::Client.new(settings.google_client_id, settings.google_client_secret, {
                                         :site => "https://accounts.google.com",
                                         :authorize_url => "/o/oauth2/auth",
                                         :token_url => "/o/oauth2/token"
                                       })

SCOPE = "https://www.googleapis.com/auth/userinfo.profile"

Faye::WebSocket.load_adapter("thin")

helpers do
  def stringify_error(e)
    buffer = Array.new
    buffer << e.class.name + ": " + e.message
    while e do
      e.backtrace.each do |loc|
        buffer << "\tfrom " + loc
      end
      e = e.cause
      if e then
        buffer << "Caused by " + e.class.name + ": " + e.message
      end
    end
    return buffer.join("\n")
  end

  def redirect_uri
    uri = URI.parse(request.url)
    uri.path = "/oauth2/callback"
    uri.query = nil
    uri.to_s
  end
end

def send_permission_groups(ws)
  ws.send({:type => "step_data", :step => "permgroup", :content => PermissionGroup.all.map do |pg|
             next {
               :name => pg.name,
               :id => pg.id,
               :nodeValues => Hash[pg.permissions.map do |p|
                                     [
                                       p.permission_node,
                                       p.permitted
                                     ]
                                   end]
             }
           end}.to_json)
  puts "sent permission groups"
end
loaded_models = false

get "/" do
  if Faye::WebSocket.websocket?(request.env)
    ws = Faye::WebSocket.new(request.env, nil, {ping: 15})
    has_lock = false
    ws.on :open do |event|
      if settings.setup_lock.try_lock then
        has_lock = true
        if loaded_models then
          send_permission_groups ws
        end
        ws.send({:type => "switch_step", :step => settings.setup_step}.to_json);
      else
        ws.send({:type => "switch_step", :step => "locked"}.to_json);
        settings.sockets_waiting.push(ws)
      end
    end
    ws.on :close do |event|
      if has_lock then
        settings.setup_lock.unlock
        settings.sockets_waiting.each do |sock|
          sock.send({:type => "switch_step", :step => "begin"}.to_json);
        end
        settings.sockets_waiting.clear
      else
        settings.sockets_waiting.delete ws
      end
    end
    ws.on :message do |event|
      dat = JSON.parse(event.data)
      if has_lock
        if dat["step"] != settings.setup_step then
          puts "Got setup submission for wrong step?"
        end
        case dat["step"]
        when "step1"
          begin
            DB = Sequel.connect(dat["url"], :test => true)
            class WSLogIO
              def initialize(ws)
                @ws = ws
              end
              def write(str)
                @ws.send({:type => "step_data", :step => "dbsetup", :content => str}.to_json)
              end
              def close
              end
            end
            begin
              DB.loggers << Logger.new(WSLogIO.new(ws))
              Sequel.extension :migration
              if Sequel::Migrator.is_current?(DB, "migrations") then
                puts "skipping db setup"
                require_relative "./models.rb"
                loaded_models = true
                send_permission_groups ws
                ws.send({:type => "switch_step", :step => "permgroup"}.to_json);
                settings.setup_step = "permgroup";
              else
                ws.send({:type => "switch_step", :step => "dbsetup"}.to_json);
                settings.setup_step = "dbsetup";
              end
            rescue => e
              settings.setup_step = "dbsetup";
              ws.send({:type => "step_data", :step => "dbsetup", :error => stringify_error(e)}.to_json)
            end
          rescue => e
            ws.send({:type => "step_data", :step => "step1", :error => stringify_error(e)}.to_json)
          end
        when "permgroup"
          case dat["action"]
          when "update_node"
            pg = PermissionGroup[dat["id"]]
            pg.set_permission(dat["node"], dat["permitted"])
            puts "updated permission node '#{dat["node"]}' for '#{PermissionGroup[dat["id"]].name}'"
            puts "  value: " + pg.get_permission(dat["node"]).to_s
            ws.send({:type => "permgroup_ack", :pg => dat["id"]}.to_json)
          when "submit"
            ws.send({:type => "switch_step", :step => "createadmin"}.to_json)
            settings.setup_step = "createadmin"
          end
        when "dbsetup"
          begin
            Sequel::Migrator.run(DB, "migrations")
            require_relative "./models.rb"
            loaded_models = true
            send_permission_groups ws

            ws.send({:type => "step_data", :step => "dbsetup", :content => "\nDone!", :finished => true}.to_json)
            settings.setup_step = "permgroup"
          rescue => e
            ws.send({:type => "step_data", :step => "dbsetup", :error => stringify_error(e)}.to_json)
          end
        when "createadmin"
          puts "got oauth redirect request"
          url = settings.oauth2_client.auth_code.authorize_url(:redirect_uri => redirect_uri, :scope => SCOPE, :access_type => :online, :approval_prompt => :auto, :state => "")
          ws.send({:type => "step_data", :step => "createadmin", :oauth_redirect => url}.to_json)
        end
      end
    end
    ws.rack_response
  else
    haml :setup
  end
end

get "/oauth2/callback" do
  token = settings.oauth2_client.auth_code.get_token(params[:code], :redirect_uri => redirect_uri)
  userinfo = JSON.parse(token.get("https://www.googleapis.com/oauth2/v1/userinfo?alt=json").body)

  user = User[:google_id => userinfo["id"]]
  if user == nil then
    user = User.create(:google_id => userinfo["id"])
    puts "Creating superuser '#{userinfo["name"]}'"
  else
    puts "Promoting existing user '#{userinfo["name"]}' to superuser status"
  end
  user.permission_group = PermissionGroup[:internal_id => "superusers"]
  user.save
  haml :setup_complete
end
