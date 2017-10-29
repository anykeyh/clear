require "../../src/clear"

module MigrationSpec
  extend self

  class Migration123
    include Clear::Migration

    def change(dir)
    end
  end

  puts Migration123.new.uid
end
