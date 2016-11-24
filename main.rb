require "sinatra/base"
require "oauth2"
require "haml"
require "nokogiri"
require "json"
require "sequel"
require "faraday"
require "faraday_middleware"
require "byebug"

require_relative "./config.rb"

require_relative "./picasaweb.rb"

DB = Sequel.connect("mysql2://tagger:S6L52XKuqR56PGqZujM8z2pr@localhost/tagger")

Sequel.extension :migration
Sequel::Migrator.check_current(DB, "./migrations/")

require_relative "./models.rb"

PICASA_SCOPE = "https://picasaweb.google.com/data/"
USERINFO_SCOPE = "https://www.googleapis.com/auth/userinfo.profile"

REDIRECT_NEW_USER = "/app/debug/dump/session"
REDIRECT_RETURNING_USER = "/app/debug/dump/session"
REDIRECT_POST_PHOTO_AUTH = "/app/debug/dump/session"

SESSION_VERSION = 5

class TaggerApp < Sinatra::Base
  set :session_secret, "hEHObjgcVXIctzVq" # generated from random.org
  
  enable :sessions

  set :oauth2_client, OAuth2::Client.new(G_API_CLIENT, G_API_SECRET, {
                                           :site => "https://accounts.google.com",
                                           :authorize_url => "/o/oauth2/auth",
                                           :token_url => "/o/oauth2/token"
                                         })

  set :imgur_conn, (Faraday.new(:url => "https://api.imgur.com") do |faraday|
                      faraday.authorization("Client-ID", IMGUR_API_CLIENT)
                      faraday.response :json, :content_type => /\bjson$/
                      faraday.adapter Faraday.default_adapter
                    end)
  
  helpers do
    def session_sane
      if session[:version] != SESSION_VERSION then
        redirect "/auth/google/userinfo"
        return
      end
    end

    def get_identity
      if session[:version] != SESSION_VERSION then
        session.clear
      end

      if session[:user_id] then
        return User[:id => session[:user_id]]
      else
        halt 501, "NYI"
      end
    end

    def ensure_authorization
      user = get_identity
      if params[:user] == "me" || params[:user].to_i == user.id then
        return user
      else
        content_type :json
        halt 401, {:status => :error, :reason => :not_authorized, :message => "Not authorized."}.to_json
      end
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

    def create_user(google_id)
      user = User.create(:google_id => session[:google_id])
      untagged = Tag.create(:title => "Untagged")
      untagger.user = user
      return user
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

    if session[:version] != SESSION_VERSION then
      redirect "/auth/google/userinfo"
      next
    end
    
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
