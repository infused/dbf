require "spec_helper"

describe DBF::Record do

  describe '#to_a' do
    let(:table) { DBF::Table.new "#{DB_PATH}/dbase_83.dbf" }
    it 'should return an ordered array of attribute values' do
      record = table.record(0)
      expect(record.to_a).to eq [87, 2, 0, 0, 87, "1", "Assorted Petits Fours", "graphics/00000001/t_1.jpg", "graphics/00000001/1.jpg", 0.0, 0.0, "Our Original assortment...a little taste of heaven for everyone.  Let us\r\nselect a special assortment of our chocolate and pastel favorites for you.\r\nEach petit four is its own special hand decorated creation. Multi-layers of\r\nmoist cake with combinations of specialty fillings create memorable cake\r\nconfections. Varietes include; Luscious Lemon, Strawberry Hearts, White\r\nChocolate, Mocha Bean, Roasted Almond, Triple Chocolate, Chocolate Hazelnut,\r\nGrand Orange, Plum Squares, Milk chocolate squares, and Raspberry Blanc.", 5.51, true, true]

      record = table.record(9)
      expect(record.to_a).to eq [34, 1, 0, 0, 34, "AB01", "Apricot Brandy Fruitcake", "graphics/00000001/t_AB01.jpg", "graphics/00000001/AB01.jpg", 37.95, 37.95, "Once tasted you will understand why we won The\r\nBoston Herald's Fruitcake Taste-off. Judges liked its generous size,\r\nluscious appearance, moist texture and fruit to cake ratio ... commented one\r\njudge \"It's a lip Smacker!\" Our signature fruitcake is baked with carefully\r\nselected ingredients that will be savored until the last moist crumb is\r\ndevoured each golden slice is brimming with Australian glaced apricots,\r\ntoasted pecans, candied orange peel, and currants, folded gently into a\r\nbrandy butter batter and slowly baked to perfection and then generously\r\nimbibed with \"Holiday Spirits\". Presented in a gift tin.  (3lbs. 4oz)", 0.0, false, true]
    end

    describe 'with missing memo file' do
      let(:table) { DBF::Table.new "#{DB_PATH}/dbase_83_missing_memo.dbf" }

      it 'returns nil values for memo fields' do
        record = table.record(0)
        expect(record.to_a).to eq [87, 2, 0, 0, 87, "1", "Assorted Petits Fours", "graphics/00000001/t_1.jpg", "graphics/00000001/1.jpg", 0.0, 0.0, nil, 1.0, false, false]
      end
    end
  end

  describe '#==' do
    let :record do
      table = DBF::Table.new "#{DB_PATH}/dbase_8b.dbf"
      table.record(9)
    end

    describe 'when other does not have attributes' do
      it 'is false' do
        expect((record == mock('other'))).to be_false
      end
    end

    describe 'if other attributes match' do
      it 'is true' do
        attributes = {:x => 1, :y => 2}
        record.stub!(:attributes).and_return(attributes)
        other = mock('object', :attributes => attributes)
        expect((record == other)).to be_true
      end
    end

  end

  describe 'column accessors' do
    let(:table) { DBF::Table.new "#{DB_PATH}/dbase_8b.dbf"}
    let(:record) { table.find(0) }

    it 'should have dynamic accessors for the columns' do
      expect(record).to respond_to(:character)
      expect(record.character).to eq 'One'
      expect(record.float).to eq 1.23456789012346
      expect(record.logical).to eq true
    end

    it 'should not define accessor methods on the base class' do
      second_table = DBF::Table.new "#{DB_PATH}/dbase_03.dbf"
      second_record = second_table.find(0)
      expect(record.character).to eq 'One'
      expect { second_record.character }.to raise_error(NoMethodError)
    end
  end

  describe 'column data for table' do
    describe 'using specified in dbf encoding' do
      let(:table) { DBF::Table.new "#{DB_PATH}/cp1251.dbf"}

      let(:record) { table.find(0) }
      it 'should automatically encodes to default system encoding' do
        if table.supports_encoding?
          expect(record.name.encoding).to eq Encoding.default_external
          expect(record.name.encode("UTF-8").unpack("H4")).to eq ["d0b0"] # russian a
        end
      end
    end

    describe 'overriding specified in dbf encoding' do
      let(:table) { DBF::Table.new "#{DB_PATH}/cp1251.dbf", nil, 'cp866'}

      let(:record) { table.find(0) }
      it 'should transcode from manually specified encoding to default system encoding' do
        if table.supports_encoding?
          expect(record.name.encoding).to eq Encoding.default_external
          expect(record.name.encode("UTF-8").unpack("H4")).to eq ["d180"] # russian а encoded in cp1251 and read as if it was encoded in cp866
        end
      end
    end
  end

  describe '#attributes' do
    let(:table) { DBF::Table.new "#{DB_PATH}/dbase_8b.dbf"}
    let(:record) { table.find(0) }

    it 'is a hash of attribute name/value pairs' do
      expect(record.attributes).to be_a(Hash)
      expect(record.attributes['CHARACTER']).to eq 'One'
    end

    it 'has only original field names as keys' do
      original_field_names = %w(CHARACTER DATE FLOAT LOGICAL MEMO NUMERICAL)
      expect(record.attributes.keys.sort).to eq original_field_names
    end
  end
end
