class NoDefaultUserGrantedError < StandardError
  def initialize(grant)
    @grant = grant
  end

  attr_reader :grant
end

class AccessDeniedError < StandardError
  def initialize(grant, object, message)
    @grant = grant
    @object = object
    @message = message
  end

  attr_reader :grant
  attr_reader :object
  attr_reader :message
end

class NoSuchObjectExistsError < StandardError
  def initialize(object_type, id)
    @object_type = object_type
    @id = id
  end

  attr_reader :object_type
  attr_reader :id
end
