class NoDefaultUserGrantedError < StandardError
  def initialize(grant)
    @grant = grant
  end

  attr_reader :grant
end

class AccessDeniedError < StandardError
  def initialize(grant, object)
    @grant = grant
    @object = object
  end

  attr_reader :grant
  attr_reader :object
end

class NoSuchObjectExistsError < StandardError
  def initialize(object_type, id)
    @object_type = object_type
    @id = id
  end

  attr_reader :object_type
  attr_reader :id
end
