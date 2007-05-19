module DBF
  
  DBF_HEADER_SIZE = 32
  FPT_HEADER_SIZE = 512
  FPT_BLOCK_HEADER_SIZE = 8
  DATE_REGEXP = /([\d]{4})([\d]{2})([\d]{2})/
  VERSION_DESCRIPTIONS = {
    "02" => "FoxBase",
    "03" => "dBase III without memo file",
    "04" => "dBase IV without memo file",
    "05" => "dBase V without memo file",
    "30" => "Visual FoxPro",
    "31" => "Visual FoxPro with AutoIncrement field",
    "7b" => "dBase IV with memo file",
    "83" => "dBase III with memo file",
    "8b" => "dBase IV with memo file",
    "8e" => "dBase IV with SQL table",
    "f5" => "FoxPro with memo file",
    "fb" => "FoxPro without memo file"
  }
    
  class DBFError < StandardError; end
  class UnpackError < DBFError; end
  
  class Reader
    attr_reader :field_count
    attr_reader :fields
    attr_reader :record_count
    attr_reader :version
    attr_reader :last_updated
    attr_reader :memo_file_format
    attr_reader :memo_block_size
    
    def initialize(file)
      @data_file = File.open(file, 'rb')
      @memo_file = open_memo(file)
      reload!
    end
    
    def reload!
      get_header_info
      get_memo_header_info if @memo_file
      get_field_descriptors
    end
    
    def has_memo_file?
      @memo_file ? true : false
    end
    
    def open_memo(file)
      %w(fpt FPT dbt DBT).each do |extension|
        filename = file.sub(/dbf$/i, extension)
        if File.exists?(filename)
          @memo_file_format = extension.downcase.to_sym
          return File.open(filename, 'rb')
        end
      end
      nil
    end
    
    def field(field_name)
      @fields.detect {|f| f.name == field_name.to_s}
    end
    
    # An array of all the records contained in the database file
    def records
      seek_to_record(0)
      @records ||= Array.new(@record_count) do |i|
        if active_record?
          Record.new(self, @data_file, @memo_file)
        else
          seek_to_record(i + 1)
          nil
        end
      end
    end
    
    alias_method :rows, :records
    
    # Returns the record at <a>index</i> by seeking to the record in the
    # physical database file. See the documentation for the records method for
    # information on how these two methods differ.
    def record(index)
      seek_to_record(index)
      active_record? ? Record.new(self, @data_file, @memo_file) : nil
    end
    
    alias_method :row, :record
    
    def version_description
      VERSION_DESCRIPTIONS[version]
    end
    
    private
    
    # Returns false if the record has been marked as deleted, otherwise it returns true. When dBase records are deleted a
    # flag is marking the record as deleted. The record will not be fully removed until the database has been compacted.
    def active_record?
      @data_file.read(1).unpack('H2').to_s == '20'
    rescue
      false
    end
    
    def get_header_info
      @data_file.rewind
      @version, @record_count, @header_length, @record_length = @data_file.read(DBF_HEADER_SIZE).unpack('H2xxxVvv')
      @field_count = (@header_length - DBF_HEADER_SIZE + 1) / DBF_HEADER_SIZE
    end
    
    def get_field_descriptors
      @fields = []
      @field_count.times do
        name, type, length, decimal = @data_file.read(32).unpack('a10xax4CC')
        if length > 0 && !name.strip.empty?
          @fields << Field.new(name, type, length, decimal)
        end
      end
      # adjust field count
      @field_count = @fields.size
      @fields
    end
    
    def get_memo_header_info
      @memo_file.rewind
      if @memo_file_format == :fpt
        @memo_next_available_block, @memo_block_size = @memo_file.read(FPT_HEADER_SIZE).unpack('Nxxn')
      else
        @memo_block_size = 512
        @memo_next_available_block = File.size(@memo_file.path) / @memo_block_size
      end
    endIndex: test/foxpro_read_test.rb
===================================================================
--- test/foxpro_read_test.rb	(revision 32)
+++ test/foxpro_read_test.rb	(working copy)
@@ -24,4 +24,10 @@
     @dbf = DBF::Reader.new(File.join(File.dirname(__FILE__),'databases', 'foxpro.dbf'))
   end
   
+  # make sure we're grabbing the correct memo
+  def test_memo_contents
+    assert_equal "jos\202 vicente salvador\r\ncapell\205: salvador vidal\r\nen n\202ixer, les castellers li van fer un pilar i el van entregar al seu pare.", 
+      @dbf.records[3]['OBSE']
+  end
+  
 end
\ No newline at end of file
Index: lib/dbf/reader.rb
===================================================================
--- lib/dbf/reader.rb	(revision 46)
+++ lib/dbf/reader.rb	(working copy)
@@ -29,6 +29,7 @@
     attr_reader :version
     attr_reader :last_updated
     attr_reader :memo_file_format
+    attr_reader :memo_block_size
     
     def initialize(file)
       @data_file = File.open(file, 'rb')
@@ -61,35 +62,12 @@
       @fields.detect {|f| f.name == field_name.to_s}
     end
     
-    def memo(start_block)
-      @memo_file.rewind
-      @memo_file.seek(start_block * @memo_block_size)
-      if @memo_file_format == :fpt
-        memo_type, memo_size, memo_string = @memo_file.read(@memo_block_size).unpack("NNa56")
-        if memo_size > @memo_block_size - FPT_BLOCK_HEADER_SIZE
-          memo_string << @memo_file.read(memo_size - @memo_block_size + FPT_BLOCK_HEADER_SIZE)
-        end
-      else
-        if version == "83" # dbase iii
-          memo_string = ""
-          loop do
-            memo_string << block = @memo_file.read(512)
-            break if block.strip.size < 512
-          end
-        elsif version == "8b" # dbase iv
-          memo_type, memo_size = @memo_file.read(8).unpack("LL")
-          memo_string = @memo_file.read(memo_size)
-        end
-      end
-      memo_string
-    end
-    
     # An array of all the records contained in the database file
     def records
       seek_to_record(0)
       @records ||= Array.new(@record_count) do |i|
         if active_record?
-          build_record
+          Record.new(self, @data_file, @memo_file)
         else
           seek_to_record(i + 1)
           nil
@@ -104,7 +82,7 @@
     # information on how these two methods differ.
     def record(index)
       seek_to_record(index)
-      active_record? ? build_record : nil
+      active_record? ? Record.new(self, @data_file, @memo_file) : nil
     end
     
     alias_method :row, :record
@@ -123,38 +101,6 @@
       false
     end
     
-    # Returns a record with all fields typecast.
-    #--
-    # This needs to be refactored so that you can simply call Record.new(@fields).  This means that Field will need to 
-    # learn typecasting so that Record can simply enermerate the fields and call field.value on each.  We should also
-    # allow field.value_before_typecast.
-    def build_record
-      record = Record.new(self)
-      @fields.each do |field| 
-        case field.type
-        when 'N' # number
-          record[field.name] = field.decimal == 0 ? unpack_integer(field) : unpack_float(field)
-        when 'D' # date
-          raw = unpack_string(field).to_s.strip
-          unless raw.empty?
-            begin
-              record[field.name] = Time.gm(*raw.match(DATE_REGEXP).to_a.slice(1,3).map {|n| n.to_i})
-            rescue
-              record[field.name] = Date.new(*raw.match(DATE_REGEXP).to_a.slice(1,3).map {|n| n.to_i})
-            end
-          end
-        when 'M' # memo
-          starting_block = unpack_integer(field)
-          record[field.name] = starting_block == 0 ? nil : memo(starting_block)
-        when 'L' # logical
-          record[field.name] = unpack_string(field) =~ /^(y|t)$/i ? true : false
-        else
-          record[field.name] = unpack_string(field)
-        end
-      end
-      record
-    end
-    
     def get_header_info
       @data_file.rewind
       @version, @record_count, @header_length, @record_length = @data_file.read(DBF_HEADER_SIZE).unpack('H2xxxVvv')
@@ -189,25 +135,9 @@
     end
     
     def seek_to_record(index)
-      seek(@record_length * index)
+      seek(index * @record_length)
     end
     
-    def unpack_field(field)
-      @data_file.read(field.length).unpack("a#{field.length}")
-    end
-    
-    def unpack_string(field)
-      unpack_field(field).to_s
-    end
-    
-    def unpack_integer(field)
-      unpack_string(field).to_i
-    end
-    
-    def unpack_float(field)
-      unpack_string(field).to_f
-    end
-    
   end
   
   class FieldError < StandardError; end
@@ -227,6 +157,64 @@
   end
   
   class Record < Hash
+    def initialize(reader, data_file, memo_file)
+      @reader, @data_file, @memo_file = reader, data_file, memo_file
+      reader.fields.each do |field| 
+        case field.type
+        when 'N' # number
+          self[field.name] = field.decimal == 0 ? unpack_string(field).to_i : unpack_string(field).to_f
+        when 'D' # date
+          raw = unpack_string(field).strip
+          unless raw.empty?
+            begin
+              self[field.name] = Time.gm(*raw.match(DATE_REGEXP).to_a.slice(1,3).map {|n| n.to_i})
+            rescue
+              self[field.name] = Date.new(*raw.match(DATE_REGEXP).to_a.slice(1,3).map {|n| n.to_i})
+            end
+          end
+        when 'M' # memo
+          starting_block = unpack_string(field).to_i
+          self[field.name] = read_memo(starting_block)
+        when 'L' # logical
+          self[field.name] = unpack_string(field) =~ /^(y|t)$/i ? true : false
+        else
+          self[field.name] = unpack_string(field)
+        end
+      end
+      self
+    end
+    
+    def unpack_field(field)
+      @data_file.read(field.length).unpack("a#{field.length}")
+    end
+    
+    def unpack_string(field)
+      unpack_field(field).to_s
+    end
+    
+    def read_memo(start_block)
+      return nil if start_block == 0
+      @memo_file.seek(start_block * @reader.memo_block_size)
+      if @reader.memo_file_format == :fpt
+        memo_type, memo_size, memo_string = @memo_file.read(@reader.memo_block_size).unpack("NNa56")
+        if memo_size > (@reader.memo_block_size - FPT_BLOCK_HEADER_SIZE)
+          memo_string << @memo_file.read(memo_size - @reader.memo_block_size + FPT_BLOCK_HEADER_SIZE)
+        end
+      else
+        case @reader.version
+        when "83" # dbase iii
+          memo_string = ""
+          loop do
+            memo_string << block = @memo_file.read(512)
+            break if block.strip.size < 512
+          end
+        when "8b" # dbase iv
+          memo_type, memo_size = @memo_file.read(8).unpack("LL")
+          memo_string = @memo_file.read(memo_size)
+        end
+      end
+      memo_string
+    end
   end
 
 end

    
    def seek(offset)
      @data_file.seek(@header_length + offset)
    end
    
    def seek_to_record(index)
      seek(index * @record_length)
    end
    
  end
  
  class FieldError < StandardError; end
  
  class Field
    attr_accessor :name, :type, :length, :decimal

    def initialize(name, type, length, decimal)
      raise FieldError, "field length must be greater than 0" unless length > 0
      self.name, self.type, self.length, self.decimal = name.strip, type, length, decimal
    end

    def name=(name)
      @name = name.gsub(/\0/, '')
    end

  end
  
  class Record < Hash
    def initialize(reader, data_file, memo_file)
      @reader, @data_file, @memo_file = reader, data_file, memo_file
      reader.fields.each do |field| 
        case field.type
        when 'N' # number
          self[field.name] = field.decimal == 0 ? unpack_string(field).to_i : unpack_string(field).to_f
        when 'D' # date
          raw = unpack_string(field).strip
          unless raw.empty?
            begin
              self[field.name] = Time.gm(*raw.match(DATE_REGEXP).to_a.slice(1,3).map {|n| n.to_i})
            rescue
              self[field.name] = Date.new(*raw.match(DATE_REGEXP).to_a.slice(1,3).map {|n| n.to_i})
            end
          end
        when 'M' # memo
          starting_block = unpack_string(field).to_i
          self[field.name] = read_memo(starting_block)
        when 'L' # logical
          self[field.name] = unpack_string(field) =~ /^(y|t)$/i ? true : false
        else
          self[field.name] = unpack_string(field)
        end
      end
      self
    end
    
    def unpack_field(field)
      @data_file.read(field.length).unpack("a#{field.length}")
    end
    
    def unpack_string(field)
      unpack_field(field).to_s
    end
    
    def read_memo(start_block)
      return nil if start_block == 0
      @memo_file.seek(start_block * @reader.memo_block_size)
      if @reader.memo_file_format == :fpt
        memo_type, memo_size, memo_string = @memo_file.read(@reader.memo_block_size).unpack("NNa56")
        if memo_size > (@reader.memo_block_size - FPT_BLOCK_HEADER_SIZE)
          memo_string << @memo_file.read(memo_size - @reader.memo_block_size + FPT_BLOCK_HEADER_SIZE)
        end
      else
        case @reader.version
        when "83" # dbase iii
          memo_string = ""
          loop do
            memo_string << block = @memo_file.read(512)
            break if block.strip.size < 512
          end
        when "8b" # dbase iv
          memo_type, memo_size = @memo_file.read(8).unpack("LL")
          memo_string = @memo_file.read(memo_size)
        end
      end
      memo_string
    end
  end

end
