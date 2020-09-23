require "spec"
require "json"

macro columns_to_instance_vars
  struct Assigner
    include JSON::Serializable

    {% for name, settings in COLUMNS %}
      getter {{name.id}} : {{settings[:type]}}?
    {% end %}

    def json_to_new
      assign_model_from_json({{@type}}.new) # Loop through instance variables and assign to the newly created orm instance
    end

    def json_to_update(to_update_model)
      assign_model_from_json(to_update_model) # Loop through instance variables and assign to the orm instance you are updating
    end

    macro finished
      def assign_model_from_json(model)
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
    Assigner.from_json(string_or_io).json_to_new
  end

  def self.update_from_json(model, string_or_io)
    Assigner.from_json(string_or_io).json_to_update(model)
  end
end

module Clear::Model::JSONSerializable
  macro included
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
end

module Clear::Model
  include Clear::Model::JSONSerializable
end

# # Usage
class ItemTest
  include Clear::Model

  column id : Int64, primary: true, presence: false
  column title : String
  column body : String?
  column published : Bool?
end

it "should create a new ItemTest", focus: true do
  i1_body = {title: "Pure Title", body: "Pure Body", published: false}
  i1 = ItemTest.pure_from_json(i1_body.to_json)
  i1.title.should eq(i1_body["title"])
  i1.body.should eq(i1_body["body"])
  i1.published.should eq(i1_body["published"])

  i2_body = {title: "New Title", body: "New Body", published: true}
  i2 = ItemTest.new_from_json(i2_body.to_json)
  i2.title.should eq(i2_body["title"])
  i2.body.should eq(i2_body["body"])
  i2.published.should eq(i2_body["published"])

  i3_body = {title: "Updated Title"}
  i3 = ItemTest.update_from_json(i2, i3_body.to_json)
  i3.title.should eq(i3_body["title"])
  i3.body.should eq(i2_body["body"])
  i3.published.should eq(i2_body["published"])
end
