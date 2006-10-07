= DBF
A dBase i/o library.

== Features

  * No external dependencies
  * DB fields are type cast
  * Date/Time fields are returned as either a Time or Date object.  Date 
    will only be used if the date is outside the range for Time.
  
== Limitations
  
  * Writing to the db has not been implemented yet
  
== Usage

  reader = DBF::Reader.new("old_data.dbf")
  
  reader.records.each do |record|
    puts record['name']
    puts record['email']
  end
  
  puts reader.records[4]['name']
  puts reader.record(4)['name']
  
=== A note on record vs. records

DBF::Reader#records is an in-memory array of all rows in the database.  All
rows are loaded the first time that the method is called.  Subsequent calls
retrieve the row from memory.

DBF::Reader#record retrieves the requested row from the database each time
it is called. 

Using records is probably faster most of the time.  Record is more appropriate 
for very large databases where you don't want the whole db loaded into memory.
