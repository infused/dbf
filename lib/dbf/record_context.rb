# frozen_string_literal: true

module DBF
  RecordContext = Struct.new(:columns, :version, :memo, :column_offsets, keyword_init: true)
end
