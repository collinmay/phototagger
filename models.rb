require "sequel"
require_relative "utils.rb"

class User < Sequel::Model
  one_to_many :tags
  one_to_many :photos
  many_to_one :permission_group

  def validate
    super
    if !google_id || google_id.length < 2 then
      errors.add(:google_id, "cannot be empty")
    end
  end
end
User.unrestrict_primary_key

class Tag < Sequel::Model
  many_to_many :photos
  many_to_one :user
end

class Photo < Sequel::Model
  one_to_one :google_photo
  one_to_one :imgur_photo
  many_to_many :tags
  many_to_one :user
  
  def to_hash
    {
      :id => id,
      :user => user_id,
      :provider => provider,
      :provider_id => provider_id,
      :fullres_url => fullres_url,
      :is_video => is_video,
      :thumbnail_url => thumbnail_url
    }
  end
  
  def provider_id
    case provider
    when "imgur"
      return imgur_photo ? imgur_photo.imgur_id : nil
    when "gphotos"
      return google_photo ? google_photo.google_id : nil
    else
      return nil
    end
  end

  def fullres_url
    case provider
    when "imgur"
      return imgur_photo.fullres_url
    when "gphotos"
      return google_photo.fullres_url
    else
      return nil
    end
  end

  def thumbnail_url
    case provider
    when "imgur"
      return imgur_photo.thumbnail_url
    when "gphotos"
      return google_photo.thumbnail_url
    end
  end
  
  def error_check
    errors = []

    begin
      case provider
      when "imgur"
        if imgur_photo == nil then
          errors.push "No associated imgur photo"
        else
          errors.concat(imgur_photo.error_check)
        end
      when "gphotos"
        if google_photo == nil then
          errors.push "No associated google photo"
        else
          errors.concat(google_photo.error_check)
        end
      else
        errors.push "Unknown provider '" + provider
      end
    rescue => e
      errors.push e
    end

    return errors
  end
end

class GooglePhoto < Sequel::Model
  many_to_one :photo

  def error_check
    errors = []
    
    if photo == nil then
      errors.push "No associated photo"
    end

    if google_id == nil then
      errors.push "No associated google ID"
    end

    if google_id.to_s == 0 then
      if google_id == "0" then
        errors.push "Google ID is zero"
      else
        errors.push "Google ID is not a number"
      end
    end

    if !valid_uri?(fullres_url)
      errors.push "Full res URL is not a valid URL (" + fullres_url.inspect + ")"
    end

    if !valid_uri?(largethumb_url) then
      errors.push "Large thumbnail URL is not a valid URL (" + largethumb_url.inspect + ")"
    end

    return errors
  end

  def thumbnail_url
    largethumb_url
  end
end
GooglePhoto.unrestrict_primary_key

class ImgurPhoto < Sequel::Model
  many_to_one :photo

  def error_check
    errors = []

    if photo == nil then
      errors.push "No associated photo"
    end

    if imgur_id.length != 7 then
      errors.push "Imgur ID is not 7 characters long"
    end

    if !valid_uri?(fullres_url) then
      errors.push "Full res URL is not a valid URL (" + fullres_url.inspect + ")"
    end
    
    return errors
  end

  def thumbnail_url
    i = fullres_imgthumb_url.rindex(".")
    return fullres_imgthumb_url[0, i] + "b" + fullres_imgthumb_url[i, fullres_imgthumb_url.length]
  end
end
ImgurPhoto.unrestrict_primary_key

class Permission < Sequel::Model
  many_to_one :permission_group

  def to_s
    "#" + id.to_s + " " + permission_node + ": " + permitted.to_s + " for #" + permission_group.id.to_s + " " + permission_group.name
  end
end

class PermissionGroup < Sequel::Model
  one_to_many :permissions
  one_to_many :users
  
  def get_permission(node)
    return permissions_dataset[:permission_node => node]
  end

  def set_permission(node, permitted)
    p = get_permission(node) || Permission.new
    p.permission_group = self
    p.permission_node = node
    p.permitted = permitted
    p.save
    return p
  end

  def has_permission(node)
    prm = get_permission(node)
    return prm && prm.permitted
  end
end
