require "sinatra/base"
require "sinatra/config_file"
require "sinatra/partial"
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

REDIRECT_NEW_USER = "/app/round/"
REDIRECT_RETURNING_USER = "/app/round/"

SESSION_VERSION = 5

class TaggerApp < Sinatra::Base
  register Sinatra::ConfigFile
  register Sinatra::Partial
  
  config_file "./config.yml"
  DB = Sequel.connect(settings.db_path)
  Sequel.extension :migration
  if settings.test? then # automatically apply migrations for unit tests
    Sequel::Migrator.run(DB, "migrations")
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

  before do
    request.env["grant"] = grant
  end

  helpers do
    def grant
      @grant ||= CookieGrant.new(session)
    end
    
    def user
      if @user then
        return @user
      end
      
      if !params[:user] || params[:user] == "me" then
        if grant.default_user then
          @user = grant.protect(grant.default_user)
        else
          raise NoDefaultUserGrantedError.new(@user)
        end
      else
        @user = grant.protect(User[:id => params[:user].to_i])
        if @user == nil then
          raise NoSuchObjectExistsError.new(:user, params[:user].to_i)
        end
      end

      return @user
    end

    def photo
      if @photo then
        return @photo
      end

      if !params[:photo_id] then
        raise NoObjectSpecifiedError.new(:photo)
      end

      @photo = grant.protect(Photo[:id => params[:photo_id].to_i])
      if @photo == nil then
        raise NoSuchObjectExistsError.new(:photo, params[:photo_id].to_i)
      end

      return @photo
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
      if !grant.grants_import_imgur_photo?(user) then
        raise AccessDeniedError.new(grant, user, "not allowed to create imgur image for specified user")
      end
      
      photo = Photo.create(:provider => "imgur", :is_video => image["animated"])
      imgur_photo = ImgurPhoto.create(
        :imgur_id => image["id"],
        :photo_id => photo.id,
        :fullres_imgthumb_url => image["link"],
        :fullres_url => image["animated"] ? image["mp4"] : image["link"])
      
      user.add_photo(photo)
      return photo
    end

    def import_imgur_album(user, album)
      album["images"].map do |image|
        import_imgur_image(user, image)
      end
    end

    def import_imgur_favorites(user, username)
      json = settings.imgur_conn.get("/3/account/#{Faraday::Utils.escape(username)}/gallery_favorites").body
      if !json["success"] then
        raise json["data"]["error"]
      end
      
      return json["data"].reduce([]) do |photos, entity|
        if entity["is_album"] then
          json2 = settings.imgur_conn.get("/3/album/#{entity["id"]}").body
          if !json2["success"] then
            raise json["data"]["error"]
          end
          photos.concat(import_imgur_album(user, json2["data"]))
        else
          photos.push(import_imgur_image(user, entity))
        end
        next photos
      end
    end
    
    def import_gphoto(user, image)
      photo = Photo.create(:provider => "gphotos", :is_video => image.fullsize.medium == "video")
      google_photo = GooglePhoto.create(
        :google_id => image.id,
        :fullres_url => image.fullsize.url,
        :largethumb_url => image.thumbnails.max { |a,b| a.width <=> b.width}.url,
        :photo_id => photo.id)

      user.add_photo(photo)
      return photo
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

  require_relative "./round_interface.rb"
  
  get "/app/" do
    user # ensure logged in
    haml :app_root
  end

  def redirect_uri
    uri = URI.parse(request.url)
    uri.path = "/oauth2/callback"
    uri.query = nil
    uri.to_s
  end
end
