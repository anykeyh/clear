require "../spec_helper"

module MigrationSpec
  extend self

  class Migration123
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
    it "can apply migration up" do
      Migration123.new.apply(Clear::Migration::Direction::UP)

      Clear::Reflection::Table.public.each do |t|
        puts "table = #{t.table_name}"
        puts "column count = #{t.columns.count}"
      end
    end
  end
end
