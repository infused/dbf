# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe 'bin/dbf' do
  let(:bin) { File.expand_path('../../bin/dbf', __dir__) }
  let(:dbf_fixture) { fixture('dbase_83.dbf') }

  Result = Struct.new(:stdout, :stderr, :exit_status) do
    def success?
      exit_status.zero?
    end
  end

  def run(*args)
    original_argv = ARGV.dup
    original_stdout = $stdout
    original_stderr = $stderr
    ARGV.replace(args)
    $stdout = StringIO.new
    $stderr = StringIO.new
    status = 0
    begin
      load bin
    rescue SystemExit => e
      status = e.status
    rescue Exception => e # rubocop:disable Lint/RescueException
      $stderr.puts "#{e.class}: #{e.message}"
      status = 1
    end
    Result.new($stdout.string, $stderr.string, status)
  ensure
    ARGV.replace(original_argv)
    $stdout = original_stdout
    $stderr = original_stderr
  end

  describe '-v' do
    it 'prints the gem version' do
      result = run('-v')
      expect(result.success?).to be true
      expect(result.stdout).to eq "dbf version: #{DBF::VERSION}\n"
    end
  end

  describe '-h' do
    it 'prints usage with each documented flag' do
      result = run('-h')
      expect(result.success?).to be true
      expect(result.stdout).to include 'usage:'
      %w[-h -v -s -a -r -c].each { |flag| expect(result.stdout).to include "#{flag} =" }
    end
  end

  describe 'no filename given' do
    it 'exits non-zero with an explanatory message' do
      result = run
      expect(result.success?).to be false
      expect(result.stderr).to include 'You must supply a filename'
    end
  end

  describe '-s' do
    it 'prints summary information' do
      result = run('-s', dbf_fixture)
      expect(result.success?).to be true
      expect(result.stdout).to include "Database: #{dbf_fixture}"
      expect(result.stdout).to include 'Type: (83)'
      expect(result.stdout).to include 'Memo File: true'
      expect(result.stdout).to include 'Records: 67'
      expect(result.stdout).to include 'Fields:'
      expect(result.stdout).to include 'NAME'
    end
  end

  describe '-a' do
    it 'matches the ActiveRecord schema fixture' do
      result = run('-a', dbf_fixture)
      expect(result.success?).to be true
      expect(result.stdout.strip).to eq File.read(fixture('dbase_83_schema_ar.txt')).strip
    end
  end

  describe '-r' do
    it 'matches the Sequel schema fixture' do
      result = run('-r', dbf_fixture)
      expect(result.success?).to be true
      expect(result.stdout.strip).to eq File.read(fixture('dbase_83_schema_sq.txt')).strip
    end
  end

  describe '-c' do
    it 'emits CSV output with header and record rows' do
      result = run('-c', dbf_fixture)
      expect(result.success?).to be true
      lines = result.stdout.lines
      expect(lines.first).to include '"ID"'
      expect(lines.first).to include '"NAME"'
      expect(lines.size).to be > 1
    end
  end

  describe 'with a nonexistent file' do
    it 'exits non-zero' do
      result = run('-s', 'no_such_file.dbf')
      expect(result.success?).to be false
      expect(result.stderr).to include 'FileNotFoundError'
    end
  end
end
