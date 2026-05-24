# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe DBF::CLI do
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:dbf_fixture) { fixture('dbase_83.dbf') }

  def run(*argv)
    status = described_class.run(argv, stdout: stdout, stderr: stderr)
    [status, stdout.string, stderr.string]
  end

  describe '-v' do
    it 'prints the gem version' do
      status, out, = run('-v')
      expect(status).to eq 0
      expect(out).to eq "dbf version: #{DBF::VERSION}\n"
    end
  end

  describe '-h' do
    it 'prints usage with each documented flag' do
      status, out, = run('-h')
      expect(status).to eq 0
      expect(out).to include 'usage:'
      %w[-h -v -s -a -r -c].each { |flag| expect(out).to include "#{flag} =" }
    end
  end

  describe 'no filename given' do
    it 'exits non-zero with an explanatory message' do
      status, _, err = run
      expect(status).to eq 1
      expect(err).to include 'You must supply a filename'
    end
  end

  describe '-s' do
    it 'prints summary information' do
      status, out, = run('-s', dbf_fixture)
      expect(status).to eq 0
      expect(out).to include "Database: #{dbf_fixture}"
      expect(out).to include 'Type: (83)'
      expect(out).to include 'Memo File: true'
      expect(out).to include 'Records: 67'
      expect(out).to include 'Fields:'
      expect(out).to include 'NAME'
    end
  end

  describe '-a' do
    it 'matches the ActiveRecord schema fixture' do
      status, out, = run('-a', dbf_fixture)
      expect(status).to eq 0
      expect(out.strip).to eq File.read(fixture('dbase_83_schema_ar.txt')).strip
    end
  end

  describe '-r' do
    it 'matches the Sequel schema fixture' do
      status, out, = run('-r', dbf_fixture)
      expect(status).to eq 0
      expect(out.strip).to eq File.read(fixture('dbase_83_schema_sq.txt')).strip
    end
  end

  describe '-c' do
    it 'emits CSV output with header and record rows' do
      status, out, = run('-c', dbf_fixture)
      expect(status).to eq 0
      lines = out.lines
      expect(lines.first).to include '"ID"'
      expect(lines.first).to include '"NAME"'
      expect(lines.size).to be > 1
    end
  end

  describe 'with a nonexistent file' do
    it 'exits non-zero and reports the error to stderr' do
      status, _, err = run('-s', 'no_such_file.dbf')
      expect(status).to eq 1
      expect(err).to include 'DBF::FileNotFoundError'
      expect(err).to include 'no_such_file.dbf'
    end
  end
end
