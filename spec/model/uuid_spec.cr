require "../spec_helper"

module UUIDSpec
  class UUIDObjectMigration43293
    include Clear::Migration

    def change(dir)
      create_table(:dbobjects, id: :uuid) do |t|
        t.string :name, null: false
      end
    end
  end

  class DBObject
    include Clear::Model

    self.table = "dbobjects"

    primary_key type: :uuid
    column name : String
  end

  def self.reinit
    reinit_migration_manager
    UUIDObjectMigration43293.new.apply(Clear::Migration::Direction::UP)
  end

  describe "Clear::Model::HasSerialPkey with uuid" do
    it "can generate objects with UUID as primary keys" do
      temporary do
        reinit

        3.times do |x|
          DBObject.create!({name: "obj#{x}"})
        end

        DBObject.query.count.should eq 3

        DBObject.query.first!.id.to_s.size.should eq "00e7efec-d526-44d6-ae46-17b21af8ba87".size
        DBObject.query.last!.id.to_s.should_not eq "00000000-0000-0000-0000-000000000000"

        # Test with UUID selection:

        first_uuid = DBObject.query.select("id").first!.id
        # where clause with UUID object
        DBObject.query.where { id == first_uuid }.count.should eq 1
        DBObject.query.where { id == UUID.random }.count.should eq 0
        # Where with string version of UUID
        DBObject.query.where { id == "#{first_uuid}" }.count.should eq 1
      end
    end

    it "can save a model with UUID to JSON" do
      temporary do
        reinit

        3.times do |x|
          DBObject.create!({name: "obj#{x}"})
        end

        (
          DBObject.query.first!.to_json =~
            /"id":"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"/
        ).should eq 1
      end
    end
  end
end
