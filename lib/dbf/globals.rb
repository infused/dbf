module DBF
  DBF_HEADER_SIZE = 32
  FPT_HEADER_SIZE = 512
  BLOCK_HEADER_SIZE = 8
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
  
  class DBFError < StandardError
  end
end