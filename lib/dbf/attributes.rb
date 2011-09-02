class Attributes < Hash
  def []=(key, value)
    merge!(key => value)
    merge!(Util.underscore(key) => value)
  end
end