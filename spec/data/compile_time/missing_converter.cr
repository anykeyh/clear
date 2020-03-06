require "../../../src/clear"

record MyCustomRecord, first_name : String, last_name : String

class MyModel
  include Clear::Model

  primary_key

  column x : MyCustomRecord
end