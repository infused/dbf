# frozen_string_literal: true

module DBF
  # Base class for all errors raised by the DBF library, so callers can
  # rescue DBF::Error to catch anything the library raises.
  class Error < StandardError
  end

  # A file cannot be opened. The message names only the file, not its
  # directory, so an app that shows error messages to users does not reveal
  # server paths; #path has the full path for logging.
  class FileError < Error
    # @return [String, nil] the full path of the file
    attr_reader :path

    def initialize(message = nil, path: nil)
      super(message)
      @path = path
    end
  end

  class FileNotFoundError < FileError
  end

  # A file exists but cannot be opened, e.g. it is a directory or is not
  # readable.
  class FileAccessError < FileError
  end

  # The encoding passed to Table.new is unknown, or Ruby cannot transcode
  # it to Unicode.
  class UnsupportedEncodingError < Error
  end

  class NoColumnsDefined < Error
  end
end
