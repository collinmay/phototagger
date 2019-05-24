class UserProxy
  def initialize(grant, user)
    @target = user
    @grant = grant
  end

  {
    [:photos] => :grants_list_user_photos?,
    [:tags] => :grants_list_user_tags?,
    [:add_photo] => :grants_add_photo_for?,
    [:add_tag] => :grants_add_tag_for?,
    [:remove_photo] => :grants_remove_photo_for?,
    [:remove_tag] => :grants_remove_tag_for?
  }.each_pair do |k, v|
    k.each do |name|
      define_method(name) do |*args|
        if @grant.send(v, @target) then
          return @target.send(name, *args)
        else
          raise AccessDeniedError.new(self, @target)
        end
      end
    end
  end

  # I really hope you know what you're doing.
  def unprotect
    @target
  end
  
  ["id", "google_id", "permission_group", "is_superuser", "permission_group_id"].each do |name|
    define_method(name) do |*args|
      return @target.send(name, *args)
    end
  end

  attr_reader :grant
end

class StandardGrant
  def protect(object)
    if object == nil then
      return nil
    else
      if grants_generic_access?(object)
        case object
        when User
          return UserProxy.new(self, object)
        when Photo
          return PhotoProxy.new(self, object)
        end
      else
        raise AccessDeniedError.new(self, object)
      end
    end
  end
end

class CookieGrant < StandardGrant
  def initialize(session)
    @session = session
  end

  def permission_group
    return default_user.permission_group
  end

  def has_permission(node)
    return permission_group.has_permission(node)
  end

  [:grants_list_user_photos?, :grants_list_user_tags?, :grants_add_photo_for?, :grants_add_tag_for?, :grants_remove_photo_for?, :grants_remove_tag_for?].each do |name|
    define_method(name) do |user|
      return user.id == default_user.id
    end
  end
  
  def grants_generic_access?(object)
    case object
    when User
      return object.id == @session[:user_id] || has_permission("privacy.photos.read.other")
    when Photo
      return object.user.id == @session[:user_id] || has_permission("privacy.photos.read.other")
    end
  end

  def default_user
    @user ||= User[:id => @session[:user_id]]
  end
end

class DebugGrant < StandardGrant
  def initialize(session)
    @session = session
  end
  
  def method_missing(method, *args, &block)
    if method.id2name.start_with?("grants_") && method.id2name.end_with?("?") then
      return true
    else
      super
    end
  end

  def protect(object)
    return object
  end

  def default_user
    @user ||= User[:id => @session[:user_id]]
  end
end
