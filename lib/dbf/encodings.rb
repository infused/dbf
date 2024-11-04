module DBF
  # Mapping of DBF code page markers to Ruby encoding strings
  # Reference: https://webstore.iec.ch/preview/info_isoiec10646%7Bed3.0%7Den.pdf
  ENCODINGS = {
    # Western European & English
    '03' => 'cp1252',      # Windows ANSI
    '57' => 'cp1252',      # ANSI
    '58' => 'cp1252',      # Western European ANSI  
    '59' => 'cp1252',      # Spanish ANSI

    # US & Western Europe DOS
    '01' => 'cp437',       # U.S. MS-DOS
    '02' => 'cp850',       # International MS-DOS
    '1b' => 'cp437',       # English OEM (U.S.)
    '37' => 'cp850',       # English OEM (U.S.)*
    
    # United Kingdom
    '19' => 'cp437',       # English OEM (Britain)
    '1a' => 'cp850',       # English OEM (Britain)*

    # Western European Languages
    '09' => 'cp437',       # Dutch OEM
    '0a' => 'cp850',       # Dutch OEM*
    '0d' => 'cp437',       # French OEM
    '0e' => 'cp850',       # French OEM*
    '0f' => 'cp437',       # German OEM
    '10' => 'cp850',       # German OEM*
    '11' => 'cp437',       # Italian OEM
    '12' => 'cp850',       # Italian OEM*
    '18' => 'cp437',       # Spanish OEM

    # Nordic Languages
    '08' => 'cp865',       # Danish OEM
    '0b' => 'cp437',       # Finnish OEM
    '15' => 'cp437',       # Swedish OEM
    '16' => 'cp850',       # Swedish OEM*
    '17' => 'cp865',       # Norwegian OEM
    '66' => 'cp865',       # Nordic MS-DOS
    '67' => 'cp861',       # Icelandic MS-DOS

    # Eastern European
    '1f' => 'cp852',       # Czech OEM
    '22' => 'cp852',       # Hungarian OEM
    '23' => 'cp852',       # Polish OEM
    '40' => 'cp852',       # Romanian OEM
    '64' => 'cp852',       # Eastern European MS-DOS
    '87' => 'cp852',       # Slovenian OEM
    'c8' => 'cp1250',      # Eastern European Windows

    # Cyrillic
    '26' => 'cp866',       # Russian OEM
    '65' => 'cp866',       # Russian MS-DOS
    'c9' => 'cp1251',      # Russian Windows

    # Greek & Turkish
    '6a' => 'cp737',       # Greek MS-DOS (437G)
    '86' => 'cp737',       # Greek OEM
    'cb' => 'cp1253',      # Greek Windows
    '6b' => 'cp857',       # Turkish MS-DOS
    '88' => 'cp857',       # Turkish OEM
    'ca' => 'cp1254',      # Turkish Windows

    # Asian Languages
    '13' => 'cp932',       # Japanese Shift-JIS
    '7b' => 'cp932',       # Japanese Shift-JIS
    '4d' => 'cp936',       # Chinese GBK (PRC)
    '7a' => 'cp936',       # PRC GBK
    '4e' => 'cp949',       # Korean (ANSI/OEM)
    '79' => 'cp949',       # Hangul (Wansung)
    '4f' => 'cp950',       # Chinese Big5 (Taiwan)
    '78' => 'cp950',       # Taiwan Big 5

    # Other Languages/Regions
    '1c' => 'cp863',       # French OEM (Canada)
    '1d' => 'cp850',       # French OEM*
    '6c' => 'cp863',       # French-Canadian MS-DOS
    '24' => 'cp860',       # Portuguese OEM
    '25' => 'cp850',       # Portuguese OEM*
    '50' => 'cp874',       # Thai (ANSI/OEM)
    '7c' => 'cp874',       # Thai Windows/MS-DOS
    'cc' => 'cp1257'       # Baltic Windows
  }.freeze
end
