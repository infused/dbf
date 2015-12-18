# encoding: ascii-8bit

require 'spec_helper'

RSpec.describe DBF::Column do
  let(:table) { DBF::Table.new fixture('dbase_30.dbf')}

  context 'when initialized' do
    let(:column) { DBF::Column.new table, 'ColumnName', 'N', 1, 0 }

    it 'sets :name accessor' do
      expect(column.name).to eq 'ColumnName'
    end

    it 'sets :type accessor' do
      expect(column.type).to eq 'N'
    end

    it 'sets the #length accessor' do
      expect(column.length).to eq 1
    end

    it 'sets the #decimal accessor' do
      expect(column.decimal).to eq 0
    end

    it 'accepts length of 0' do
      column = DBF::Column.new table, 'ColumnName', 'N', 0, 0
      expect(column.length).to eq 0
    end

    describe 'with length less than 0' do
      it 'raises DBF::Column::LengthError' do
        expect { DBF::Column.new table, 'ColumnName', 'N', -1, 0 }.to raise_error(DBF::Column::LengthError)
      end
    end

    describe 'with empty column name' do
      it 'raises DBF::Column::NameError' do
        expect { DBF::Column.new table, "\xFF\xFC", 'N', 1, 0 }.to raise_error(DBF::Column::NameError)
      end
    end
  end

  context '#type_cast' do
    context 'with type N (number)' do
      context 'when value is empty' do
        it 'returns nil' do
          value = ''
          column = DBF::Column.new table, 'ColumnName', 'N', 5, 2
          expect(column.type_cast(value)).to be_nil
        end
      end

      context 'and 0 length' do
        it 'returns nil' do
          column = DBF::Column.new table, 'ColumnName', 'N', 0, 0
          expect(column.type_cast('')).to be_nil
        end
      end

      context 'and 0 decimals' do
        it 'casts value to Fixnum' do
          value = '135'
          column = DBF::Column.new table, 'ColumnName', 'N', 3, 0
          expect(column.type_cast(value)).to eq 135
        end

        it 'supports negative Fixnum' do
          value = '-135'
          column = DBF::Column.new table, 'ColumnName', 'N', 3, 0
          expect(column.type_cast(value)).to eq (-135)
        end
      end

      context 'and more than 0 decimals' do
        it 'casts value to Float' do
          value = '13.5'
          column = DBF::Column.new table, 'ColumnName', 'N', 2, 1
          expect(column.type_cast(value)).to eq 13.5
        end

        it 'casts negative value to Float' do
          value = '-13.5'
          column = DBF::Column.new table, 'ColumnName', 'N', 2, 1
          expect(column.type_cast(value)).to eq (-13.5)
        end
      end
    end

    context 'with type F (float)' do
      context 'and 0 length' do
        it 'returns nil' do
          column = DBF::Column.new table, 'ColumnName', 'F', 0, 0
          expect(column.type_cast('')).to be_nil
        end
      end

      it 'casts value to Float' do
        value = '135'
        column = DBF::Column.new table, 'ColumnName', 'F', 3, 0
        expect(column.type_cast(value)).to eq 135.0
      end

      it 'casts negative value to Float' do
        value = '-135'
        column = DBF::Column.new table, 'ColumnName', 'F', 3, 0
        expect(column.type_cast(value)).to eq (-135.0)
      end
    end

    context 'with type B (binary)' do
      context 'with Foxpro dbf' do
        it 'casts to float' do
          column = DBF::Column.new table, 'ColumnName', 'B', 1, 2
          expect(column.type_cast("\xEC\x51\xB8\x1E\x85\x6B\x31\x40")).to be_a(Float)
          expect(column.type_cast("\xEC\x51\xB8\x1E\x85\x6B\x31\x40")).to eq 17.42
        end

        it 'stores original precision' do
          column = DBF::Column.new table, 'ColumnName', 'B', 1, 0
          expect(column.type_cast("\xEC\x51\xB8\x1E\x85\x6B\x31\x40")).to be_a(Float)
          expect(column.type_cast("\xEC\x51\xB8\x1E\x85\x6B\x31\x40")).to eq 17.42
        end

        it 'supports negative binary' do
          column = DBF::Column.new table, 'ColumnName', 'B', 1, 2
          expect(column.type_cast("\x00\x00\x00\x00\x00\xC0\x65\xC0")).to be_a(Float)
          expect(column.type_cast("\x00\x00\x00\x00\x00\xC0\x65\xC0")).to eq (-174.0)
        end
      end
    end

    context 'with type I (integer)' do
      context 'and 0 length' do
        it 'returns nil' do
          column = DBF::Column.new table, 'ColumnName', 'I', 0, 0
          expect(column.type_cast('')).to be_nil
        end
      end

      it 'casts value to Fixnum' do
        value = "\203\171\001\000"
        column = DBF::Column.new table, 'ColumnName', 'I', 3, 0
        expect(column.type_cast(value)).to eq 96643
      end

      it 'supports negative Fixnum' do
        value = "\x24\xE1\xFF\xFF"
        column = DBF::Column.new table, 'ColumnName', 'I', 3, 0
        expect(column.type_cast(value)).to eq (-7900)
      end
    end

    context 'with type L (logical/boolean)' do
      let(:column) { DBF::Column.new table, 'ColumnName', 'L', 1, 0 }

      it "casts 'y' to true" do
        expect(column.type_cast('y')).to be true
      end

      it "casts 't' to true" do
        expect(column.type_cast('t')).to be true
      end

      it "casts value other than 't' or 'y' to false" do
        expect(column.type_cast('n')).to be false
      end

      context 'and 0 length' do
        it 'returns nil' do
          column = DBF::Column.new table, 'ColumnName', 'L', 0, 0
          expect(column.type_cast('')).to be_nil
        end
      end
    end

    context 'with type T (datetime)' do
      let(:column) { DBF::Column.new table, 'ColumnName', 'T', 16, 0 }

      context 'with valid datetime' do
        it 'casts to DateTime' do
          expect(column.type_cast("Nl%\000\300Z\252\003")).to eq DateTime.parse('2002-10-10T17:04:56+00:00')
        end
      end

      context 'with invalid datetime' do
        it 'casts to nil' do
          expect(column.type_cast("Nl%\000\000A\000\999")).to be_nil
        end
      end

      context 'and 0 length' do
        it 'returns nil' do
          column = DBF::Column.new table, 'ColumnName', 'T', 0, 0
          expect(column.type_cast('')).to be_nil
        end
      end
    end

    context 'with type D (date)' do
      let(:column) { DBF::Column.new table, 'ColumnName', 'D', 8, 0 }

      context 'with valid date' do
        it 'casts to Date' do
          expect(column.type_cast('20050712')).to eq Date.new(2005,7,12)
        end
      end

      context 'with invalid date' do
        it 'casts to nil' do
          expect(column.type_cast('0')).to be_nil
        end
      end

      context 'and 0 length' do
        it 'returns nil' do
          column = DBF::Column.new table, 'ColumnName', 'D', 0, 0
          expect(column.type_cast('')).to be_nil
        end
      end
    end

    context 'with type M (memo)' do
      it 'casts to string' do
        column = DBF::Column.new table, 'ColumnName', 'M', 3, 0
        expect(column.type_cast('abc')).to eq 'abc'
      end

      it 'casts nil to nil' do
        column = DBF::Column.new table, 'ColumnName', 'M', 3, 0
        expect(column.type_cast(nil)).to be_nil
      end

      context 'and 0 length' do
        it 'returns nil' do
          column = DBF::Column.new table, 'ColumnName', 'M', 0, 0
          expect(column.type_cast('')).to be_nil
        end
      end
    end

    context 'with type G (memo)' do
      it 'returns binary data' do
        column = DBF::Column.new table, 'ColumnName', 'G', 3, 0
        expect(column.type_cast("\000\013\120")).to eq "\000\013\120"
        expect(column.type_cast("\000\013\120").encoding).to eq Encoding::ASCII_8BIT
      end

      it 'casts nil to nil' do
        column = DBF::Column.new table, 'ColumnName', 'G', 3, 0
        expect(column.type_cast(nil)).to be_nil
      end

      context 'and 0 length' do
        it 'returns nil' do
          column = DBF::Column.new table, 'ColumnName', 'G', 0, 0
          expect(column.type_cast('')).to be_nil
        end
      end
    end
  end

  context 'with type Y (currency)' do
    let(:column) { DBF::Column.new table, 'ColumnName', 'Y', 8, 4 }

    it 'casts to float' do
      expect(column.type_cast(" \xBF\x02\x00\x00\x00\x00\x00")).to eq 18.0
    end

    it 'supports negative currency' do
      expect(column.type_cast("\xFC\xF0\xF0\xFE\xFF\xFF\xFF\xFF")).to eq (-1776.41)
    end

    it 'supports 64bit negative currency' do
      expect(column.type_cast("pN'9\xFF\xFF\xFF\xFF")).to eq (-333609.0)
    end

    context 'and 0 length' do
      it 'returns nil' do
        column = DBF::Column.new table, 'ColumnName', 'Y', 0, 0
        expect(column.type_cast('')).to be_nil
      end
    end
  end

  context '#schema_definition' do
    context 'with type N (number)' do
      it 'outputs an integer column' do
        column = DBF::Column.new table, 'ColumnName', 'N', 1, 0
        expect(column.schema_definition).to eq "\"column_name\", :integer\n"
      end
    end

    context 'with type B (binary)' do
      context 'with Foxpro dbf' do
        it 'outputs a float column' do
          column = DBF::Column.new table, 'ColumnName', 'B', 1, 2
          expect(column.schema_definition).to eq "\"column_name\", :float\n"
        end
      end
    end

    it 'defines a float colmn if type is (N)umber with more than 0 decimals' do
      column = DBF::Column.new table, 'ColumnName', 'N', 1, 2
      expect(column.schema_definition).to eq "\"column_name\", :float\n"
    end

    it 'defines a date column if type is (D)ate' do
      column = DBF::Column.new table, 'ColumnName', 'D', 8, 0
      expect(column.schema_definition).to eq "\"column_name\", :date\n"
    end

    it 'defines a datetime column if type is (D)ate' do
      column = DBF::Column.new table, 'ColumnName', 'T', 16, 0
      expect(column.schema_definition).to eq "\"column_name\", :datetime\n"
    end

    it 'defines a boolean column if type is (L)ogical' do
      column = DBF::Column.new table, 'ColumnName', 'L', 1, 0
      expect(column.schema_definition).to eq "\"column_name\", :boolean\n"
    end

    it 'defines a text column if type is (M)emo' do
      column = DBF::Column.new table, 'ColumnName', 'M', 1, 0
      expect(column.schema_definition).to eq "\"column_name\", :text\n"
    end

    it 'defines a string column with length for any other data types' do
      column = DBF::Column.new table, 'ColumnName', 'X', 20, 0
      expect(column.schema_definition).to eq "\"column_name\", :string, :limit => 20\n"
    end
  end

  context '#name' do
    it 'contains only ASCII characters' do
      column = DBF::Column.new table, "--\x1F-\x68\x65\x6C\x6C\x6F world-\x80--", 'N', 1, 0
      expect(column.name).to eq '---hello world---'
    end

    it 'is truncated at the null character' do
      column = DBF::Column.new table, "--\x1F-\x68\x65\x6C\x6C\x6F \x00 world-\x80--", 'N', 1, 0
      expect(column.name).to eq '---hello '
    end
  end
end
