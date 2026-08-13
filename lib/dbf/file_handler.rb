# frozen_string_literal: true

module DBF
  module FileHandler
    module_function

    def open_data(data)
      case data
      when StringIO
        data
      when String
        File.open(data, 'rb')
      else
        raise ArgumentError, 'data must be a file path or an IO-like object responding to #read and #seek' unless data.respond_to?(:read) && data.respond_to?(:seek)

        # DBF is a binary format; a File opened in text mode would corrupt
        # reads on Windows.
        data.binmode if data.respond_to?(:binmode)
        data
      end
    rescue Errno::ENOENT
      raise DBF::FileNotFoundError, "file not found: #{data}"
    end

    def open_memo(data, memo, memo_class, version)
      if memo
        meth = memo.is_a?(String) ? :open : :new
        memo_class.send(meth, memo, version)
      elsif (path = data_path(data))
        found = Dir.glob(memo_search_path(path)).first
        found && memo_class.open(found, version)
      end
    end

    def data_path(data)
      return data if data.is_a?(String)

      data.path if data.respond_to?(:path)
    end

    def memo_search_path(path)
      dirname = File.dirname(path)
      basename = File.basename(path, '.*')
      "#{dirname}/#{basename}*.{fpt,FPT,dbt,DBT}"
    end
  end
end
