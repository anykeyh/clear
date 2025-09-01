require "../../spec_helper"
require "json"

module JSONConverterSpec
  # Example found here:
  #   https://codeblogmoney.com/json-example-with-data-types-including-json-array/
  JSON_DATA_SAMPLE = <<-JSON
  {
    "Actors": [
      {
        "name": "Tom Cruise",
        "age": 56,
        "Born At": "Syracuse, NY",
        "Birthdate": "July 3, 1962",
        "photo": "https://jsonformatter.org/img/tom-cruise.jpg",
        "wife": null,
        "weight": 67.5,
        "hasChildren": true,
        "hasGreyHair": false,
        "children": [
          "Suri",
          "Isabella Jane",
          "Connor"
        ]
      },
      {
        "name": "Robert Downey Jr.",
        "age": 53,
        "Born At": "New York City, NY",
        "Birthdate": "April 4, 1965",
        "photo": "https://jsonformatter.org/img/Robert-Downey-Jr.jpg",
        "wife": "Susan Downey",
        "weight": 77.1,
        "hasChildren": true,
        "hasGreyHair": false,
        "children": [
          "Indio Falconer",
          "Avri Roel",
          "Exton Elias"
        ]
      }
    ]
  }
  JSON

  class Actor
    include JSON::Serializable

    @[JSON::Field]
    property name : String

    @[JSON::Field]
    property age : Int8

    @[JSON::Field(key: "Born At")]
    property born_at : String

    @[JSON::Field(key: "Birthdate")]
    property born_date : String

    @[JSON::Field]
    property photo : String

    @[JSON::Field]
    property wife : String?

    @[JSON::Field]
    property weight : Float64

    @[JSON::Field(key: "hasChildren")]
    property? has_children : Bool

    @[JSON::Field(key: "hasGreyHair")]
    property? has_grey_hair : Bool

    @[JSON::Field]
    property children : Array(String)
  end

  class Data
    include JSON::Serializable

    @[JSON::Field(key: "Actors")]
    property actors : Array(Actor)
  end

  class JsonConverterSpec14
    include Clear::Migration

    def change(dir)
      create_table "json_models" do |t|
        t.column "actor", "jsonb", null: false, index: true
      end
    end
  end

  class JsonModel
    include ::Clear::Model

    self.table = "json_models"

    primary_key

    column actor : Actor
  end

  describe "Clear::Model::Converter::JSON::AnyConverter" do
    it "converts from JSON::Any" do
      json_any = JSON.parse(JSON_DATA_SAMPLE)
      converter = Clear::Model::Converter::JSON::AnyConverter

      converter.to_column(JSON_DATA_SAMPLE).should eq(json_any)
    end

    it "converts using json_serializable_converter" do
      temporary do
        reinit_migration_manager
        JsonConverterSpec14.new.apply

        d = Data.from_json(JSON_DATA_SAMPLE)

        d.actors.each do |actor|
          JsonModel.create!({actor: actor})
        end

        model = JsonModel.query.first!

        actor = model.actor
        actor.name = "Tommy Cruise"
        model.actor_column.dirty!
        model.save!

        tommy = JsonModel.query.where { var("actor").jsonb("children").contains?("Suri") }.first!
        tommy.actor.name.should eq("Tommy Cruise")
      end
    end
  end
end

Clear.json_serializable_converter(JSONConverterSpec::Actor)
