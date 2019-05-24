class TaggerApp < Sinatra::Base
  get "/api/whoami" do
    content_type :json
    {:status => :success,
     :grant_type => grant.class.name,
     :google_id => user.google_id, :id => user.id}.to_json
  end

  get "/api/photo/:photo_id" do
    content_type :json
    {:status => :success,
     :photo => photo.to_hash
    }.to_json
  end
  
  get "/api/user/:user/photo/list" do
    content_type :json
    {:status => :success,
     :owner => user.id,
     :photos => user.photos.map do |photo|
       photo.to_hash
     end}.to_json
  end

  post "/api/user/:user/photo/import/imgur/favorites/" do
    content_type :json

    request.body.rewind
    data = JSON.parse request.body.read
    valid_keys = ["username"]
    if data.keys.sort == valid_keys.sort then
      next {
        :status => :success,
        :owner => user.id,
        :photos => import_imgur_favorites(grant.protect(user), data["username"]).map do |photo|
          photo.to_hash
        end}.to_json
    else
      status 400
      next {
        :status => :error,
        :reason => "malformed_request",
        :model_type => "photo",
        :malformation => "extra_keys",
        :extra_keys => (data.keys - valid_keys),
        :message => "Malformed request: imgur favorites import job contains extra keys."
      }.to_json
    end
  end
  
  post "/api/user/:user/photo/" do
    content_type :json
    
    request.body.rewind
    data = JSON.parse request.body.read
    valid_keys = ["provider", "provider_id"]
    if data.keys.sort == valid_keys.sort then
      case data["provider"]
      when "imgur"
        imgur_response = settings.imgur_conn.get("/3/image/" + data["provider_id"])
        imgur_json = imgur_response.body
        if imgur_response.status == 404 then
          status 404
          next {
            :status => :error,
            :reason => "not_found",
            :model_type => "photo",
            :given_id => data["provider_id"],
            :given_provider => "imgur",
            :message => "No such image found on imgur '#{data["provider_id"]}'."
          }.to_json
        elsif !imgur_json["success"] then
          status 400
          next {
            :status => :error,
            :reason => "foreign_imgur",
            :foreign_error => imgur_json
          }.to_json
        else
          photo = import_imgur_image(user, json["data"])
          status 200
          next {:status => :success, :photo => photo.to_hash}.to_json
        end
      when "gphotos"
        status 500 # TODO
        next {
          :status => :error,
          :reason => "NYI"
        }.to_json
      else
        status 400
        next {
          :status => :error,
          :reason => "malformed_request",
          :model_type => "photo",
          :malformation => "bad_field",
          :bad_field => "provider",
          :bad_value => data["provider"],
          :message => "Malformed request: unknown provider '#{data["provider"]}'."
        }.to_json
      end
    else
      status 400
      next {
        :status => :error,
        :reason => "malformed_request",
        :model_type => "photo",
        :malformation => "extra_keys",
        :extra_keys => (data.keys - valid_keys),
        :message => "Malformed request: photo contains extra keys."
      }.to_json
    end
  end

  [NoSuchObjectExistsError,AccessDeniedError].each do |err|
    error err do
      err = env["sinatra.error"]
      if request.path[0,5] == "/api/" then
        content_type :json
        status 401
        {
          :status => "error",
          :reason => "access denied"
        }.to_json
      else
        raise err
      end
    end
  end

  error NoDefaultUserGrantedError do
    err = env["sinatra.error"]
    if request.path[0,5] == "/api/" then
      content_type :json
      status 401
      {
        :status => "error",
        :reason => "no default user granted"
      }.to_json
    else
      raise err
    end
  end
end
