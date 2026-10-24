# frozen_string_literal: true

module DBF
  # Base class for all errors raised by the DBF library, so callers can
  # rescue DBF::Error to catch anything the library raises.
  class Error < StandardError
  end

  class FileNotFoundError < Error
  end

  # A file exists but cannot be opened, e.g. it is a directory or is not
  # readable.
  class FileAccessError < Error
  end

  # The encoding passed to Table.new is unknown, or Ruby cannot transcode
  # it to Unicode.
  class UnsupportedEncodingError < Error
  end

  class NoColumnsDefined < Error
  end
end
