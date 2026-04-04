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
        raise ArgumentError, 'data must be a file path or StringIO object'
      end
    rescue Errno::ENOENT
      raise DBF::FileNotFoundError, "file not found: #{data}"
    end

    def open_memo(data, memo, memo_class, version)
      if memo
        meth = memo.is_a?(StringIO) ? :new : :open
        memo_class.send(meth, memo, version)
      elsif !data.is_a?(StringIO)
        path = Dir.glob(memo_search_path(data)).first
        path && memo_class.open(path, version)
      end
    end

    def memo_search_path(io)
      dirname = File.dirname(io)
      basename = File.basename(io, '.*')
      "#{dirname}/#{basename}*.{fpt,FPT,dbt,DBT}"
    end
  end
end
