# frozen_string_literal: true

module DBF
  # Immutable per-table state shared by every record during decoding
  RecordContext = Data.define(:columns, :version, :memo, :column_offsets)
end
