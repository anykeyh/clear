require "../spec_helper"
require "./12345_migration_by_file"

module MigrationSpec
  extend self

  class Migration1
    include Clear::Migration

    def change(dir)
      create_table(:test) do |t|
        t.string :first_name
        t.string :last_name

        t.index "lower(first_name || ' ' || last_name)", using: :btree

        t.timestamps
      end
    end
  end

  describe "Migration" do
    it "can discover UID from class name" do
      Migration1.new.uid.should eq 1
    end

    it "can discover UID from file name" do
      MigrationByFile.new.uid.should eq 12345
    end

    it "can apply migration up" do
      Migration1.new.apply(Clear::Migration::Direction::UP)

      Clear::Reflection::Table.public.where { table_name == "test" }.any?.should eq true

      columns = Clear::Reflection::Table.public.find { table_name == "test" }.columns

      columns.dup.where { column_name == "first_name" }.any?.should eq true
      columns.dup.where { column_name == "last_name" }.any?.should eq true
    end
  end
end
