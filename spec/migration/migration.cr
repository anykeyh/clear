require "../../src/clear"

module MigrationSpec
  extend self

  class Migration123
    include Clear::Migration

    def change(dir)
      create_table(:test) do |t|
        t.integer :id, primary: true

        t.string :first_name
        t.string :last_name

        t.index "lower(first_name || ' ' || last_name)", using: :btree

        t.timestamps
      end
    end
  end

  puts Migration123.new.uid
  Clear::Migration::Manager.instance.apply_all
end
