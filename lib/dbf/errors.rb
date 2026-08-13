# frozen_string_literal: true

module DBF
  # Base class for all errors raised by the DBF library, so callers can
  # rescue DBF::Error to catch anything the library raises.
  class Error < StandardError
  end

  class FileNotFoundError < Error
  end

  class NoColumnsDefined < Error
  end
end
