require "spec"
require "json"

macro columns_to_instance_vars
  struct Assigner
    include JSON::Serializable
    {% for name, settings in COLUMNS %}
      getter {{name.id}} : {{settings[:type]}}?
    {% end %}

    def new_with_json
      generate_from_json({{@type}}.new) # Loop through instance variables and assign to the newly created orm instance
    end

    def update_with_json(to_update_model)
      generate_from_json(to_update_model) # Loop through instance variables and assign to the orm instance you are updating
    end

    macro finished
      def generate_from_json(model)
        {% for name, settings in COLUMNS %}
          model.{{name.id}} = @{{name.id}}.not_nil! unless @{{name.id}}.nil?
        {% end %}

        model
      end
    end
  end

  def self.pure_from_json(string_or_io)
    Assigner.from_json(string_or_io)
  end

  def self.new_from_json(string_or_io)
    Assigner.from_json(string_or_io).new_with_json
  end

  def self.update_from_json(model, string_or_io)
    Assigner.from_json(string_or_io).update_with_json(model)
  end
end

module Clear::Model::JSONSerializable
  macro included # When included into Model
    macro inherited #Polymorphism
      macro finished
        columns_to_instance_vars
      end
    end

    macro finished
      columns_to_instance_vars
    end
  end
end

# # Usage
class ItemTest
  include Clear::Model
  include Clear::Model::JSONSerializable

  column id : Int64, primary: true, presence: false
  column title : String
  column body : String?
  column published : Bool?
end

it "should create a new ItemTest", focus: true do
  i1_body = {title: "Pure Title", body: "Pure Body", published: false}
  i1 = ItemTest.pure_from_json(i1_body.to_json)
  i1.title.should eq(i1_body["title"])

  i2_body = {title: "New Title", body: "New Body", published: true}
  i2 = ItemTest.new_from_json(i2_body.to_json)
  i2.title.should eq(i2_body["title"])

  i3_body = {title: "Updated Title"}
  i3 = ItemTest.update_from_json(i2, i3_body.to_json)
  i3.title.should eq(i3_body["title"])
end
