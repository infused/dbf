class Attributes < Hash
  def []=(key, value)
    merge!(key => value)
    merge!(key.underscore => value)
  end
end