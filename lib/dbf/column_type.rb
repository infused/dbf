module DBF
  module ColumnType
    # Base class for all column type handlers
    class Base
      attr_reader :decimal, :encoding

      # Initialize a new column type handler
      # @param column [DBF::Column] The column to handle type casting for
      def initialize(column)
        @decimal = column.decimal
        @encoding = column.encoding
      end
    end

    # Handles nil/empty values
    class Nil < Base
      def type_cast(_value)
        nil
      end
    end

    # Handles numeric values with optional decimals
    class Number < Base
      def type_cast(value)
        return nil if value.strip.empty?
        @decimal.zero? ? value.to_i : value.to_f
      end
    end

    # Handles currency values stored as 64-bit integers
    class Currency < Base
      CURRENCY_FACTOR = 10_000.0

      def type_cast(value)
        (value.unpack1('q<') / CURRENCY_FACTOR).to_f
      end
    end

    # Handles 32-bit signed integers (little-endian)
    class SignedLong < Base
      def type_cast(value)
        value.unpack1('l<')
      end
    end

    # Handles alternative 32-bit signed integers using bit manipulation
    class SignedLong2 < Base
      def type_cast(value)
        binary = value.unpack1('B*')
        sign = binary[0] == '0' ? -1 : 1
        binary[1, 31].to_i(2) * sign
      end
    end

    # Handles floating point values
    class Float < Base
      def type_cast(value)
        value.to_f
      end
    end

    # Handles double precision floating point values
    class Double < Base
      def type_cast(value)
        value.unpack1('E')
      end
    end

    # Handles boolean/logical values
    class Boolean < Base
      TRUE_VALUES = /^[yt]$/i

      def type_cast(value)
        value.strip.match?(TRUE_VALUES)
      end
    end

    # Handles date values in YYYYMMDD format
    class Date < Base
      DATE_FORMAT = '%Y%m%d'
      DATE_REGEX = /\d{8}/

      def type_cast(value)
        value.match?(DATE_REGEX) && ::Date.strptime(value, DATE_FORMAT)
      rescue StandardError
        nil
      end
    end

    # Handles datetime values stored as days + milliseconds
    class DateTime < Base
      SECONDS_PER_HOUR = 3600
      SECONDS_PER_MINUTE = 60
      MSEC_TO_SEC = 1000

      def type_cast(value)
        days, msecs = value.unpack('l2')
        secs = (msecs / MSEC_TO_SEC).to_i
        hours = (secs / SECONDS_PER_HOUR).to_i
        minutes = (secs / SECONDS_PER_MINUTE).to_i % SECONDS_PER_MINUTE
        seconds = secs % SECONDS_PER_MINUTE

        ::DateTime.jd(days, hours, minutes, seconds).to_time
      rescue StandardError
        nil
      end
    end

    # Handles memo fields with encoding conversion
    class Memo < Base
      def type_cast(value)
        return value if value.nil? || !encoding

        value.force_encoding(@encoding)
             .encode(Encoding.default_external, undef: :replace, invalid: :replace)
      end
    end

    # Handles general binary data
    class General < Base
      def type_cast(value)
        value
      end
    end

    # Handles character string values with encoding conversion
    class String < Base
      def type_cast(value)
        value = value.strip
        return value unless @encoding

        value.force_encoding(@encoding)
             .encode(Encoding.default_external, undef: :replace, invalid: :replace)
      end
    end
  end
end
