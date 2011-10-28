module DBF
  class FoxproColumn < Column
    def unpack_binary(value) #nodoc
      value.unpack('d')[0]
    end
  end
end