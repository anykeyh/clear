require "../spec_helper"
require "./12345_migration_by_file"

module MigrationSpec
  extend self

  class Migration1
    include Clear::Migration

    def change(dir)
      create_table(:test) do |t|
        t.string :first_name, index: true
        t.string :last_name, unique: true

        t.index "lower(first_name || ' ' || last_name)", using: :btree

        t.timestamps
      end
    end
  end

  class Migration2
    include Clear::Migration

    def change(dir)
      add_column "test", "middle_name", "text"
      create_index "test", "middle_name DESC"
    end

    # drop_index :test_first_name
  end

  describe "Migration" do
    it "can discover UID from class name" do
      Migration1.new.uid.should eq 1
    end

    it "can discover UID from file name" do
      MigrationByFile.new.uid.should eq 12345
    end

    it "can apply migration" do
      Migration1.new.apply(Clear::Migration::Direction::UP)

      Clear::Reflection::Table.public.where { table_name == "test" }.any?.should eq true

      table = Clear::Reflection::Table.public.find { table_name == "test" }
      columns = table.columns

      columns.dup.where { column_name == "first_name" }.any?.should eq true
      columns.dup.where { column_name == "last_name" }.any?.should eq true

      table.list_indexes.size.should eq 5

      Migration2.new.apply(Clear::Migration::Direction::UP)
      columns = table.columns
      columns.dup.where { column_name == "middle_name" }.any?.should eq true
      table.list_indexes.size.should eq 6

      # Revert the last migration
      Migration2.new.apply(Clear::Migration::Direction::DOWN)
      columns = table.columns
      columns.dup.where { column_name == "middle_name" }.any?.should eq false
      table.list_indexes.size.should eq 5

      # Revert the table migration
      Migration1.new.apply(Clear::Migration::Direction::DOWN)
      Clear::Reflection::Table.public.where { table_name == "test" }.any?.should eq false
    end
  end
end
