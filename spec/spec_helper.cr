require "../src/clear"

module SpecHelper
  class SetupDatabase1
    include Clear::Migration

    def change(dir)
    end
  end
end

Clear::Migration::Manager.instance.apply_all!
