module DBF
  module Column
    class Foxpro < Base
      def unpack_binary(value) #nodoc
        value.unpack('d')[0]
      end
    end
  end
end