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
        found = find_memo(path)
        found && memo_class.open(found, version)
      end
    end

    def data_path(data)
      return data if data.is_a?(String)

      data.path if data.respond_to?(:path)
    end

    MEMO_EXTENSIONS = %w[fpt dbt].freeze

    # Finds the memo file sitting next to the data file: same basename, with
    # an .fpt or .dbt extension in any case. The directory is scanned rather
    # than globbed so glob metacharacters in an uploaded filename cannot be
    # expanded, and the basename must match exactly so data.dbf never picks
    # up an unrelated memo such as data2.fpt.
    def find_memo(path)
      dirname = File.dirname(path)
      basename = File.basename(path, '.*')
      entries = Dir.children(dirname).sort.each_with_object({}) do |child, index|
        index[child.downcase(:ascii)] ||= child
      end
      entry = MEMO_EXTENSIONS.filter_map { |ext| entries["#{basename}.#{ext}".downcase(:ascii)] }.first
      entry && File.join(dirname, entry)
    rescue SystemCallError
      nil
    end
  end
end
