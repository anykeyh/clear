require "../../../src/clear"

class MyModel
  include Clear::Model

  primary_key

  column name : String
end

MyModel.new({full_name: "Tom"}) # < Here full_name instead of name