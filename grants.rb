class CookieGrant
  def initialize(session)
    @session = session
  end

  def grants_list_user_photos?(user)
    return @session[:user_id] == User.id
  end

  def grants_generic_access?(object)
    case object
    when User
      return object.id == @session[:user_id]
    when Photo
      return object.user.id == @session[:user_id]
    end
  end

  def default_user
    return User[:id => @session[:user_id]]
  end

  def protect(object)
    if object == nil then
      return nil
    else
      if grants_generic_access?(object)
      #return object.restrict(self)
        return object
      else
        raise AccessDeniedError.new(self, object)
      end
    end
  end
end

class DebugGrant < CookieGrant
  def grants_list_user_photos?(user)
    return true
  end

  def grants_generic_access?(object)
    return true
  end

  def protect(object)
    return object
  end
end
