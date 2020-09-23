require "spec"
require "json"

macro assign_instance_var_to_columns_attr
  struct Assigner
    include JSON::Serializable

    {% for name, settings in COLUMNS %}
      getter {{name.id}} : {{settings[:type]}}?
    {% end %}
  end

  def self.pure_from_json(string_or_io)
    Assigner.from_json(string_or_io)
  end

  def self.say_hello(string_or_io)
    pp! "Hello world123"
  end
end

module Clear::Model::JSONSerializable
  macro included # When included into Model
    macro inherited #Polymorphism
      macro finished
        assign_instance_var_to_columns_attr
      end
    end

    macro finished
      assign_instance_var_to_columns_attr
    end
  end
end

# # Usage

class TestItem
  include Clear::Model
  include Clear::Model::JSONSerializable

  column id : Int64, primary: true, presence: false
  column title : String
  column body : String?
  column published : Bool?
end

it "should create a new TestItem", focus: true do
  body = {title: "Title Here 1", body: "Body Here 1", published: false}
  item = TestItem.pure_from_json(body.to_json)
  # item = TestItem.say_hello(body.to_json)

  pp! item
end
