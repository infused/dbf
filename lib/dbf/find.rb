# frozen_string_literal: true

module DBF
  # The Find module provides methods for searching and retrieving
  # records using a simple ActiveRecord-like syntax.
  #
  # Examples:
  #   table = DBF::Table.new 'mydata.dbf'
  #
  #   # Find record number 5
  #   table.find(5)
  #
  #   # Find all records for Keith Morrison
  #   table.find :all, first_name: "Keith", last_name: "Morrison"
  #
  #   # Find first record
  #   table.find :first, first_name: "Keith"
  #
  # The <b>command</b> may be a record index, :all, or :first.
  # <b>options</b> is optional and, if specified, should be a hash where the
  # keys correspond to column names in the database.  The values will be
  # matched exactly with the value in the database.  If you specify more
  # than one key, all values must match in order for the record to be
  # returned.  The equivalent SQL would be "WHERE key1 = 'value1'
  # AND key2 = 'value2'".
  module Find
    # @param command [Integer, Symbol] command
    # @param options [optional, Hash] options Hash of search parameters
    # @yield [optional, DBF::Record, NilClass]
    def find(command, options = {}, &)
      case command
      when Integer then record(command)
      when Array then command.map { |index| record(index) }
      when :all then find_all_records(options, &)
      when :first then find_first_record(options)
      end
    end

    private

    def find_all_records(options)
      select do |record|
        next unless record&.match?(options)

        yield record if block_given?
        record
      end
    end

    def find_first_record(options)
      detect { |record| record&.match?(options) }
    end
  end
end
