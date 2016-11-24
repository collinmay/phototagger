require "sinatra/base"
require "sinatra/config_file"
require "oauth2"
require "haml"
require "nokogiri"
require "json"
require "sequel"
require "faraday"
require "faraday_middleware"
require "byebug"

require_relative "./picasaweb.rb"
require_relative "./imgur.rb"

require_relative "./exceptions.rb"
require_relative "./grants.rb"

PICASA_SCOPE = "https://picasaweb.google.com/data/"
USERINFO_SCOPE = "https://www.googleapis.com/auth/userinfo.profile"

REDIRECT_NEW_USER = "/app/debug/dump/session"
REDIRECT_RETURNING_USER = "/app/debug/dump/session"
REDIRECT_POST_PHOTO_AUTH = "/app/debug/dump/session"

SESSION_VERSION = 5

class TaggerApp < Sinatra::Base
  register Sinatra::ConfigFile

  config_file "./config.yml"
  DB = Sequel.connect(settings.db_path)
  Sequel.extension :migration
  if settings.test? then # automatically apply migrations for unit tests
    Sequel::Migrator.run(DB, "migrations")
    OmniAuth.config.test_mode = true
  end
  Sequel::Migrator.check_current(DB, "migrations")
  require_relative "./models.rb"
  
  use Rack::Session::Cookie, :secret => "hEHObjgcVXIctzVq"  

  set :oauth2_client, OAuth2::Client.new(settings.google_client_id, settings.google_client_secret, {
                                           :site => "https://accounts.google.com",
                                           :authorize_url => "/o/oauth2/auth",
                                           :token_url => "/o/oauth2/token"
                                         })

  set :imgur_conn, (Faraday.new(:url => "https://api.imgur.com") do |faraday|
                      faraday.authorization("Client-ID", settings.imgur_api_client)
                      faraday.response :json, :content_type => /\bjson$/
                      faraday.adapter Faraday.default_adapter
                    end)
  
  before "/app/debug/*" do
    if session[:version] != SESSION_VERSION then
      session.clear
      session[:version] = SESSION_VERSION
    end

    if !session[:user_id] then
      redirect "/auth/google/userinfo"
    end

    @grant = DebugGrant.new(session)
  end

  helpers do
    def grant
      @grant ||= CookieGrant.new(session)
    end
    
    def user
      if @user && grant.grants_generic_access?(@user) then
        return @user
      end
      
      if !params[:user] || params[:user] == "me" then
        if grant.default_user then
          @user = grant.default_user
        else
          raise NoDefaultUserGrantedError.new(@user)
        end
      else
        @user = User[:id => params[:user].to_i]
        if @user == nil then
          raise NoSuchObjectExistsError.new(:user, params[:user].to_i)
        end
        if !grant.grants_generic_access?(@user) then
          raise AccessDeniedError.new(@grant, @user)
        end
      end

      return @user
    end
    
    def get_gphotos_token
      if !session[:photos_token] then
        redirect settings.oauth2_client.auth_code.authorize_url(:redirect_uri => redirect_uri, :scope => PICASA_SCOPE, :access_type => :online, :approval_prompt => :auto, :state => "photos/#{request.path}")
      end
      
      token = OAuth2::AccessToken.from_hash(settings.oauth2_client, session[:photos_token])
      if token.expired? then
        session[:photos_token] = nil
        redirect settings.oauth2_client.auth_code.authorize_url(:redirect_uri => redirect_uri, :scope => PICASA_SCOPE, :access_type => :online, :approval_prompt => :auto, :state => "photos/#{request.path}")
      end
      
      return token
    end

    def import_imgur_image(user, image)
      photo = Photo.create(:provider => "imgur")
      imgur_photo = ImgurPhoto.create(:imgur_id => image["id"], :photo_id => photo.id, :fullres_url => image["link"])
      
      user.add_photo(photo)
      return photo
    end

    def import_imgur_album(user, album)
      album["images"].each do |image|
        import_imgur_image(user, image)
      end
    end

    def import_gphoto(user, image)
      photo = Photo.create(:provider => "gphotos")
      google_photo = GooglePhoto.create(:google_id => image.id, :fullres_url => image.fullsize.url, :largethumb_url => image.thumbnails.max { |a,b| a.width <=> b.width}.url, :photo_id => photo.id)

      user.add_photo(photo)
    end
  end

  get "/" do
    token = nil

    if session[:userinfo_token] then
      token = OAuth2::AccessToken.from_hash(settings.oauth2_client, session[:userinfo_token])
      if token.expired? && token.refresh_token then
        token.refresh!
        session[:userinfo_token] = token.to_hash
      end
    else
      redirect "/auth/google/userinfo"
      next
    end

    if token.expired? then
      redirect "/auth/google/userinfo"
      next
    end
    
    userinfo = JSON.parse(token.get("https://www.googleapis.com/oauth2/v1/userinfo?alt=json").body)
    id = userinfo["id"]
    if(session[:google_id] != id) then
      redirect "/auth/google/userinfo"
      next
    end

    redirect REDIRECT_RETURNING_USER
  end

  require_relative "./oauth_interface.rb"
  require_relative "./api_interface.rb"
  
  if development? then
    require_relative "./debug_interface.rb"
  else
    get "/app/debug/*" do
      "Debug features only available in development mode."
    end
  end  
  
  get "/app/" do
    
  end

  def redirect_uri
    uri = URI.parse(request.url)
    uri.path = "/oauth2/callback"
    uri.query = nil
    uri.to_s
  end
end
