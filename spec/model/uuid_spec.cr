require "../spec_helper"

module UUIDSpec
  class UUIDObjectMigration43293
    include Clear::Migration

    def change(dir)

      create_table(:dbobjects, id: :uuid) do |t|
        t.column :name, :string, null: false
      end

      create_table(:dbobjects2, id: :uuid) do |t|
        t.references to: "dbobjects", name: "db_object_id", type: "uuid", null: true
      end

    end

  end

  class DBObject
    include Clear::Model

    self.table = "dbobjects"

    primary_key type: :uuid
    has_many db_objects : DBObject2, foreign_key: "db_object_id"

    column name : String
  end

  class DBObject2
    include Clear::Model

    self.table = "dbobjects2"

    belongs_to db_object : DBObject, foreign_key: "db_object_id", key_type: UUID?

    primary_key type: :uuid
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

    it "can call relations between the objects" do
      temporary do
        reinit

	3.times do |x|
          DBObject.create!({name: "obj#{x}"})
        end

        dbo_id = DBObject.query.first!.id
        obj1 = DBObject2.create!({db_object_id: dbo_id})
        obj2 = DBObject2.create!

        obj1.db_object.not_nil!.id.should eq dbo_id
        obj2.db_object.should eq nil
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
