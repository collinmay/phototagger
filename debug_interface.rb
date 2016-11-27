class TaggerApp < Sinatra::Base
  get "/app/debug/dump/session" do
    userinfo_token = OAuth2::AccessToken.from_hash(settings.oauth2_client, session[:userinfo_token]) rescue nil
    photos_token = OAuth2::AccessToken.from_hash(settings.oauth2_client, session[:photos_token]) rescue nil
    
    haml :debug_dump_info, :locals => {:session => session, :ui_tok => userinfo_token, :pho_tok => photos_token}
  end

  get "/app/debug/dump/user/:user/" do
    haml :debug_dump_user_info, :locals => {:user => user}
  end

  get "/app/debug/dump/photo/:photo/" do |photo_id|
    photo = Photo[:id => photo_id]
    if photo == nil then
      next "no such photo '#{photo_id}'"
    end

    haml :debug_dump_photo_info, :locals => {:photo => photo}
  end
  
  get "/app/debug/import/gphotos/" do
    tok = get_gphotos_token

    albums = PicasaWeb::list_albums(tok)
    haml :debug_gphotos_album_list, :locals => {:albums => albums}
  end

  get "/app/debug/import/gphotos/:albumid" do |albumid|
    user # verify stuff
    tok = get_gphotos_token
    
    photos = PicasaWeb::list_photos(tok, albumid)
    photos.each do |photo|
      import_gphoto(user, photo)
    end

    next "suc cess"
  end

  get "/app/debug/import/imgur/favorites" do
    username = params[:username]
    
    json = settings.imgur_conn.get("/3/account/#{Faraday::Utils.escape(username)}/gallery_favorites").body
    if !json["success"] then
      raise json["data"]["error"]
    end

    json["data"].each do |entity|
      if entity["is_album"] then
        json2 = settings.imgur_conn.get("/3/album/#{entity["id"]}").body
        if !json2["success"] then
          raise json["data"]["error"]
        end
        import_imgur_album(user, json2["data"])
      else
        import_imgur_image(user, entity)
      end
    end

    next "suc cess"
  end

  get "/app/debug/import/imgur/photo" do   
    regex = /\A(?:(?:https?:\/\/)?(?:i.)?imgur.com\/(?:gallery\/)?)?([a-zA-Z0-9]{5,7})(?:.[a-z0-9]{3,4})?\Z/
    m = regex.match(params[:link])
    if m then
      is_album = m[1].length == 5
      json = settings.imgur_conn.get("/3/#{is_album ? "album" : "image"}/#{m[1]}").body
      if !json["success"] then
        raise json["data"]["error"]
      end
      entity = json["data"]
      if is_album then
        import_imgur_album(user, entity)
      else
        import_imgur_image(user, entity)
      end
    else
      next "invalid imgur photo spec: " + Rack::Utils.escape_html(params[:link])
    end

    next "succ cess"
  end
  
  get "/app/debug/delete/photo/:photo_id" do |photo_id|
    photo = Photo[:id => photo_id.to_s]
    if !photo then
      next "no such photo with id #{photo_id}"
    end

    photo.destroy

    redirect back
  end
  
  get "/app/debug/userinfo_tok_refresh" do
    userinfo_token = OAuth2::AccessToken.from_hash(settings.oauth2_client, session[:userinfo_token])
    userinfo_token.refresh!
    session[:userinfo_token] = userinfo_token.to_hash
    
    photos_token = OAuth2::AccessToken.from_hash(settings.oauth2_client, session[:photos_token]) rescue nil
    
    haml :debug_dump_info, :locals => {:session => session, :ui_tok => userinfo_token, :pho_tok => photos_token}
  end
  
  get "/app/debug/logout" do
    session.clear
    redirect "/"
  end

  get "/app/debug/db/stats" do
    haml :debug_db_stats, :locals => {:db => DB}
  end

  get "/app/debug/db/inspections/users" do
    min = (params[:min] || 0).to_i
    max = (params[:max] || 20).to_i
    highlight = (params[:highlight] || 0).to_i
    range = max-min

    if range > 200 then
      next "sorry, range is too big!"
    end

    set = User.where(:id => min...max)
    
    haml :debug_db_inspections_users, :locals => {:users => set, :min => min, :max => max, :range => range, :highlight_id => highlight}
  end

  get "/app/debug/db/inspections/photos" do
    min = nil
    max = nil
    highlight = nil
    if params[:id] then
      highlight = params[:id].to_i
      min = (highlight/20).floor*20
      max = (highlight/20).floor*20+20
    else
      min = (params[:min] || 0).to_i
      max = (params[:max] || 20).to_i
      highlight = (params[:highlight] || 0).to_i
    end
    range = max-min

    if range > 200 then
      next "sorry, range is too big!"
    end

    set = Photo.where(:id => min...max)
    
    haml :debug_db_inspections_photos, :locals => {:photos => set, :min => min, :max => max, :range => range, :highlight_id => highlight}
  end

  get "/app/debug/db/purge/bad/confirm" do
    haml :debug_ays, :locals => {:message => "This may delete a lot of bad records!", :yes => "/app/debug/db/purge/bad"}
  end

  get "/app/debug/db/purge/bad" do
    Photo.all do |photo|
      if photo.error_check.length > 0 then
        photo.destroy
      end
    end

    GooglePhoto.all do |gphoto|
      if gphoto.error_check.length > 0 then
        gphoto.destroy
      end
    end

    ImgurPhoto.all do |iphoto|
      if iphoto.error_check.length > 0 then
        iphoto.destroy
      end
    end

    "done"
  end

  get "/app/debug/server/config" do
    haml :debug_srvconf,
         :locals =>
         {:config => {
            :allow_hotlinking => ALLOW_HOTLINKS,
            :allow_uploads => ALLOW_UPLOADS
          }
         }
  end
  
  get "/app/debug/" do
    haml :debug_menu
  end
end
