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

    def print_ar_schema(filename)
      @stdout.puts DBF::Table.new(filename).schema(:activerecord)
    end

    def print_sequel_schema(filename)
      @stdout.puts DBF::Table.new(filename).schema(:sequel)
    end

    def print_summary(filename)
      table = DBF::Table.new(filename)
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
        @stdout.puts format('%-16s %-10s %-10s %-10s', f.name, f.type, f.length, f.decimal)
      end
    end

    def print_csv(filename)
      DBF::Table.new(filename).to_csv(@stdout)
    end
  end
end
