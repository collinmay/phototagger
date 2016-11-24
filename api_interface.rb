class TaggerApp < Sinatra::Base
  get "/api/whoami" do
    content_type :json
    {:status => :success,
     :grant_type => grant.class.name,
     :google_id => user.google_id, :id => user.id}.to_json
  end

  get "/api/user/:user/photo/list" do
    content_type :json
    {:status => :success,
     :owner => user.id, :photos => user.photos.map do |photo|
       {
         :id => photo.id,
         :provider => photo.provider,
         :provider_id => photo.provider_id,
         :fullres_url => photo.fullres_url
       }
     end}.to_json
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
          import_imgur_image(user, json["data"])
        end
      when "gphotos"
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
        }
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
end
