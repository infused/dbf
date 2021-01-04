module DBF
  module ColumnType
    class Base
      attr_reader :decimal, :encoding

      # @param decimal [Integer]
      # @param encoding [String, Encoding]
      def initialize(decimal, encoding)
        @decimal = decimal
        @encoding = encoding
      end
    end

    class Nil < Base

      # @param _value [String]
      def type_cast(_value)
        nil
      end
    end

    class Number < Base

      # @param value [String]
      def type_cast(value)
        return nil if value.strip.empty?

        @decimal.zero? ? value.to_i : value.to_f
      end
    end

    class Currency < Base

      # @param value [String]
      def type_cast(value)
        (value.unpack1('q<') / 10_000.0).to_f
      end
    end

    class SignedLong < Base

      # @param value [String]
      def type_cast(value)
        value.unpack1('l<')
      end
    end

    class Float < Base

      # @param value [String]
      def type_cast(value)
        value.to_f
      end
    end

    class Double < Base

      # @param value [String]
      def type_cast(value)
        value.unpack1('E')
      end
    end

    class Boolean < Base

      # @param value [String]
      def type_cast(value)
        value.strip.match?(/^(y|t)$/i)
      end
    end

    class Date < Base

      # @param value [String]
      def type_cast(value)
        value.match?(/\d{8}/) && ::Date.strptime(value, '%Y%m%d')
      rescue StandardError
        nil
      end
    end

    class DateTime < Base

      # @param value [String]
      def type_cast(value)
        days, msecs = value.unpack('l2')
        secs = (msecs / 1000).to_i
        ::DateTime.jd(days, (secs / 3600).to_i, (secs / 60).to_i % 60, secs % 60).to_time
      rescue StandardError
        nil
      end
    end

    class Memo < Base

      # @param value [String]
      def type_cast(value)
        if encoding && !value.nil?
          value.force_encoding(@encoding).encode(Encoding.default_external, undef: :replace, invalid: :replace)
        else
          value
        end
      end
    end

    class General < Base

      # @param value [String]
      def type_cast(value)
        value
      end
    end

    class String < Base

      # @param value [String]
      def type_cast(value)
        value = value.strip
        @encoding ? value.force_encoding(@encoding).encode(Encoding.default_external, undef: :replace, invalid: :replace) : value
      end
    end
  end
end
