# require "../spec_helper"

# # require "../../src/clear/model/json_serializable.cr"

# module ModelJSONSerializableSpec
#   class Client
#     include Clear::Model

#     column id : Int32, primary: true, presence: false

#     column first_name : String
#     column last_name : String?
#     column middle_name : String?
#     column active : Bool?

#     timestamps
#   end

#   class ModelSpecMigration345
#     include Clear::Migration

#     def change(dir)
#       create_table(:clients) do |t|
#         t.column "first_name", "string"
#         t.column "last_name", "string"
#         t.column "active", "bool", null: true
#         t.column "middle_name", type: "varchar(32)"

#         t.timestamps
#       end
#     end
#   end

#   def self.reinit
#     reinit_migration_manager
#     ModelSpecMigration345.new.apply(Clear::Migration::Direction::UP)
#   end

#   describe "Clear::Model::JSONSerializable" do
#     it "can create a new model from json" do
#       temporary do
#         reinit

#         u1_body = {first_name: "Duke"}
#         u1 = Client.from_json(u1_body.to_json)
#         u1.first_name.should eq(u1_body["first_name"])

#         u2_body = {first_name: "Steve"}
#         u2 = Client.new(u2_body.to_json)
#         u2.first_name.should eq(u2_body["first_name"])

#         u3_body = {first_name: "Caspian"}
#         u3 = Client.set(u2, u3_body.to_json)
#         u3.first_name.should eq(u3_body["first_name"])

#         u4_body = {first_name: "George"}
#         u4 = Client.create(u4_body.to_json)
#         u4.first_name.should eq(u4_body["first_name"])

#         u5_body = {first_name: "George"}
#         u5 = Client.create!(u5_body.to_json)
#         u5.first_name.should eq(u5_body["first_name"])
#       end
#     end
#   end
# end
