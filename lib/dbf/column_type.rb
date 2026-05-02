# frozen_string_literal: true

module DBF
  module ColumnType
    class Base
      attr_reader :decimal, :encoding

      # @param decimal [Integer]
      # @param encoding [String, Encoding]
      def initialize(column)
        @decimal = column.decimal
        @encoding = column.encoding
      end

      def blank_value
        nil
      end

      def skip_blank?
        false
      end

      def decode(raw, &)
        if skip_blank? && raw.count(' ') == raw.length
          blank_value
        else
          type_cast(raw)
        end
      end
    end

    class Nil < Base
      # @param _value [String]
      def type_cast(_value)
        nil
      end
    end

    class Number < Base
      def skip_blank? = true

      # @param value [String]
      def type_cast(value)
        return nil if value.empty?

        decimal.zero? ? value.to_i : value.to_f
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

    class AutoIncrement < Base
      # @param value [String]
      def type_cast(value)
        bits = value.unpack1('B*')
        sign_multiplier = bits[0] == '0' ? -1 : 1
        bits[1, 31].to_i(2) * sign_multiplier
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
      def skip_blank? = true
      def blank_value = false

      # @param value [String]
      def type_cast(value)
        byte = value.getbyte(0)
        byte == 89 || byte == 121 || byte == 84 || byte == 116 # Y y T t
      end
    end

    class Date < Base
      def skip_blank? = true
      def blank_value = false

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
      def decode(raw, &)
        memo_content = yield(raw)
        memo_content ? type_cast(memo_content) : nil
      end

      # @param value [String]
      def type_cast(value)
        return value unless encoding && value

        value.dup.force_encoding(encoding).encode(Encoding.default_external, undef: :replace, invalid: :replace)
      end
    end

    class General < Base
      # @param value [String]
      def type_cast(value)
        value&.dup&.force_encoding(Encoding::ASCII_8BIT)
      end
    end

    class String < Base
      def initialize(column)
        super
        @target_encoding = Encoding.default_external
        @needs_encode = encoding && encoding != @target_encoding
      end

      def skip_blank? = true
      def blank_value = ''

      # @param value [String]
      def type_cast(value)
        value.strip!
        encoding ? encode(value) : value
      end

      private

      def encode(value)
        value.force_encoding(encoding)
        @needs_encode ? value.encode(@target_encoding, undef: :replace, invalid: :replace) : value
      end
    end
  end
end
