class TaggerApp < Sinatra::Base
  get "/auth/google/userinfo" do
    session.clear
    
    redirect settings.oauth2_client.auth_code.authorize_url(:redirect_uri => redirect_uri, :scope => USERINFO_SCOPE, :access_type => :online, :approval_prompt => :auto, :state => "userinfo")
  end

  get "/auth/google/photos" do
    redirect settings.oauth2_client.auth_code.authorize_url(:redirect_uri => redirect_uri, :scope => PICASA_SCOPE, :access_type => :online, :approval_prompt => :auto, :state => "photos")
  end

  get "/oauth2/callback" do
    state = params[:state]
    type = nil
    target = nil
    if state.index "/" then
      type = state[0,state.index("/")]
      target = state[state.index("/")+1,state.length]
    else
      type = state
    end
    
    uri = URI.parse(request.url)
    token = settings.oauth2_client.auth_code.get_token(params[:code], :redirect_uri => redirect_uri)

    puts "Got #{type} token: " + token.to_hash.to_s
    
    case type
    when "userinfo"
      userinfo = JSON.parse(token.get("https://www.googleapis.com/oauth2/v1/userinfo?alt=json").body)
      session[:google_id] = userinfo["id"]
      session[:google_name] = userinfo["name"]
      session[:google_picture] = userinfo["picture"]
      session[:userinfo_token] = token.to_hash
      session[:version] = SESSION_VERSION
      
      user = User[:google_id => session[:google_id]]
      if user == nil then
        user = User.create(:google_id => session[:google_id])
        
        session[:user_id] = user.id
        puts "Assigned new google user '#{user.google_id}' id #{user.id}"
        redirect REDIRECT_NEW_USER
      else
        session[:user_id] = user.id
        puts "Matched returning google user '#{user.google_id}' to id #{user.id}"
        redirect REDIRECT_RETURNING_USER
      end
    when "photos"
      session[:photos_token] = token.to_hash
      redirect target
    else
      raise "Invalid oauth2 state: '#{state}'"
    end
  end
end
