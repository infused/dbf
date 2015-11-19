module DBF
  module ColumnType
    class Base
      attr_reader :value, :decimal

      def initialize(value, decimal)
        @value = value
        @decimal = decimal
      end
    end

    class Number < Base
      def type_cast
        decimal.zero? ? value.to_i : value.to_f
      end
    end

    class Currency < Base
      def type_cast
        (value.unpack('q<')[0] / 10_000.0).to_f
      end
    end

    class SignedLong < Base
      def type_cast
        value.unpack('l<')[0]
      end
    end

    class Float < Base
      def type_cast
        value.to_f
      end
    end

    class Double < Base
      def type_cast
        value.unpack('E')[0]
      end
    end

    class Boolean < Base
      def type_cast
        value.strip =~ /^(y|t)$/i ? true : false
      end
    end

    class Date < Base
      def type_cast
        v = value.tr(' ', '0')
        v !~ /\S/ ? nil : ::Date.parse(v)
      rescue
        nil
      end
    end

    class DateTime < Base
      def type_cast
        days, msecs = value.unpack('l2')
        secs = (msecs / 1000).to_i
        ::DateTime.jd(days, (secs / 3600).to_i, (secs / 60).to_i % 60, secs % 60)
      rescue
        nil
      end
    end

    class Memo < Base
      def type_cast
        value
      end
    end

    class String < Base
      def type_cast
        value.strip
      end
    end
  end
end
