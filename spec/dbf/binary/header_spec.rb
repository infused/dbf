require 'spec_helper'

RSpec.describe DBF::Binary::Header do
  let(:dbf_path) { fixture('binary/dbase_test.dbf') }
  let(:memo_path) { fixture('binary/dbase_test.dbt') }
  let(:table) { DBF::Binary::Header.read(File.read dbf_path) }

  specify { expect(table.version).to eq '83' }
  specify { expect(table._last_update).to eq({year: 15, month: 11, day: 21}) }
  specify { expect(table._last_update.year).to eq 15 }
  specify { expect(table._last_update.month).to eq 11 }
  specify { expect(table._last_update.day).to eq 21 }
  specify { expect(table.record_count).to eq 2 }
  specify { expect(table.header_length).to eq 225 }
  specify { expect(table.record_length).to eq 50 }
  specify { expect(table.code_page_mark).to eq 3 }
  specify { expect(table.encoding).to eq 'cp1252' }

  specify do
    expect(table.field_definitions).to eq [
      DBF::Binary::Field.new(name: 'TCHAR', _field_type: 'C', field_length: 10, decimal: 0, record_offset: 1),
      DBF::Binary::Field.new(name: 'TDATE', _field_type: 'D', field_length: 8, decimal: 0, record_offset: 11),
      DBF::Binary::Field.new(name: 'TLOGICAL', _field_type: 'L', field_length: 1, decimal: 0, record_offset: 19),
      DBF::Binary::Field.new(name: 'TMEMO', _field_type: 'M', field_length: 10, decimal: 0, record_offset: 20),
      DBF::Binary::Field.new(name: 'TNUMERIC1', _field_type: 'N', field_length: 10, decimal: 0, record_offset: 30),
      DBF::Binary::Field.new(name: 'TNUMERIC2', _field_type: 'N', field_length: 10, decimal: 2, record_offset: 40)
    ]
  end

  # specify do
  #   expect(table.records).to eq []
  # end
end
