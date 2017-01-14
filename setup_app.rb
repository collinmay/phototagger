require "sinatra"
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
end

get "/" do
  if Faye::WebSocket.websocket?(request.env)
    ws = Faye::WebSocket.new(request.env, nil, {ping: 15})
    has_lock = false
    ws.on :open do |event|
      if settings.setup_lock.try_lock then
        has_lock = true
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
            require_relative "./models.rb"
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
                ws.send({:type => "switch_step", :step => "step2"}.to_json);
                settings.setup_step = "step2";
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
        when "step2"
          
        when "dbsetup"
          begin
            Sequel::Migrator.run(DB, "migrations")
            ws.send({:type => "step_data", :step => "dbsetup", :content => "\nDone!", :finished => true}.to_json)
            settings.setup_step = "step2"
          rescue => e
            ws.send({:type => "step_data", :step => "dbsetup", :error => stringify_error(e)}.to_json)
          end
        end
      end
    end
    ws.rack_response
  else
    haml :setup
  end
end
