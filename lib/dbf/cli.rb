# frozen_string_literal: true

require 'optparse'

module DBF
  class CLI
    USAGE = <<~HELP
      usage: dbf [-h|-s|-a|-c|-r] filename
        -h = print this message
        -v = print the DBF gem version
        -s = print summary information
        -a = create an ActiveRecord::Schema
        -r = create a Sequel migration
        -c = export as CSV
    HELP

    # Bytes a terminal interprets as control or escape sequences. A crafted
    # DBF can carry these in column names and record values, so they are
    # replaced before file-derived text reaches an interactive terminal.
    CONTROL_BYTES = /[\x00-\x1F\x7F]/n
    # The same, but keeping CR and LF so CSV row separators survive.
    CONTROL_BYTES_KEEPING_NEWLINES = /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/n

    # Replaces terminal control bytes. Substitution happens on a byte copy so
    # a value whose bytes are invalid in its encoding cannot raise here.
    #
    # @param value [Object]
    # @param pattern [Regexp]
    # @return [String]
    def self.sanitize(value, pattern = CONTROL_BYTES)
      string = value.to_s
      string.b.gsub(pattern, '?').force_encoding(string.encoding)
    end

    # Wraps an IO so text written to an interactive terminal is stripped of
    # control bytes. Redirected or piped output is never wrapped, so exported
    # data is passed through unaltered.
    class TerminalFilter
      def initialize(io)
        @io = io
      end

      def <<(data)
        @io << CLI.sanitize(data, CONTROL_BYTES_KEEPING_NEWLINES)
        self
      end

      def write(*data)
        @io.write(*data.map { |datum| CLI.sanitize(datum, CONTROL_BYTES_KEEPING_NEWLINES) })
      end

      def method_missing(name, ...) # :nodoc:
        @io.respond_to?(name) ? @io.send(name, ...) : super
      end

      def respond_to_missing?(name, include_private = false) # :nodoc:
        @io.respond_to?(name, include_private) || super
      end
    end

    def self.run(argv, stdout: $stdout, stderr: $stderr)
      new(argv, stdout: stdout, stderr: stderr).run
    end

    def initialize(argv, stdout: $stdout, stderr: $stderr)
      @argv = argv.dup
      @stdout = stdout
      @stderr = stderr
    end

    def run
      params = OptionParser.new.getopts(@argv, 'h', 's', 'a', 'c', 'r', 'v')

      if params['v']
        print_version
      elsif params['h']
        print_help
      else
        filename = @argv.shift
        return missing_filename unless filename

        action = %w[a r s c].find { |flag| params[flag] }
        case action
        when 'a' then print_ar_schema(filename)
        when 'r' then print_sequel_schema(filename)
        when 's' then print_summary(filename)
        when 'c' then print_csv(filename)
        end
      end
      0
    rescue DBF::FileNotFoundError => e
      @stderr.puts "DBF::FileNotFoundError: #{e.message}"
      1
    end

    private

    def print_version
      @stdout.puts "dbf version: #{DBF::VERSION}"
    end

    def print_help
      @stdout.puts USAGE
    end

    def missing_filename
      @stderr.puts 'You must supply a filename on the command line'
      1
    end

    # Always close the table when done: an open handle prevents deleting or
    # replacing the file on Windows.
    def with_table(filename)
      table = DBF::Table.new(filename)
      yield table
    ensure
      table&.close
    end

    def print_ar_schema(filename)
      with_table(filename) { |table| @stdout.puts terminal_safe(table.schema(:activerecord)) }
    end

    def print_sequel_schema(filename)
      with_table(filename) { |table| @stdout.puts terminal_safe(table.schema(:sequel)) }
    end

    def print_summary(filename)
      with_table(filename) { |table| write_summary(filename, table) }
    end

    def write_summary(filename, table)
      @stdout.puts
      @stdout.puts "Database: #{filename}"
      @stdout.puts "Type: (#{table.version}) #{table.version_description}"
      @stdout.puts "Encoding: #{table.header_encoding}" if table.header_encoding
      @stdout.puts "Memo File: #{table.has_memo_file? ? 'true' : 'false'}"
      @stdout.puts "Records: #{table.record_count}"
      @stdout.puts "\nFields:"
      @stdout.puts 'Name             Type       Length     Decimal'
      @stdout.puts '-' * 78
      table.columns.each do |f|
        # Column names and types come from the file. Always replace control
        # bytes here: they are never valid in a name and would otherwise both
        # emit escape sequences and break the column alignment below.
        @stdout.puts format('%-16s %-10s %-10s %-10s', self.class.sanitize(f.name), self.class.sanitize(f.type), f.length, f.decimal)
      end
    end

    def print_csv(filename)
      with_table(filename) { |table| table.to_csv(interactive? ? TerminalFilter.new(@stdout) : @stdout) }
    end

    # Exported data is only filtered when it is going to a terminal, so
    # redirecting or piping still produces byte-for-byte the original values.
    def terminal_safe(text)
      return text unless interactive?

      self.class.sanitize(text, CONTROL_BYTES_KEEPING_NEWLINES)
    end

    def interactive?
      @stdout.respond_to?(:tty?) && @stdout.tty?
    end
  end
end
