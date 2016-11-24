class CookieGrant
  def initialize(session)
    @session = session
  end

  def grants_list_user_photos?(user)
    return @session[:user_id] == User.id
  end

  def grants_generic_access?(object)
    if object.is_a? User then
      return object.id == @session[:user_id]
    else
      return false
    end
  end

  def default_user
    return User[:id => @session[:user_id]]
  end
end

class DebugGrant < CookieGrant
  def grants_list_user_photos?(user)
    return true
  end

  def grants_generic_access?(object)
    return true
  end
end
