require "spec"

require "../src/clear"

def initdb
  `echo "DROP DATABASE IF EXISTS clear_spec;" | psql -U postgres`
  `echo "CREATE DATABASE clear_spec;" | psql -U postgres`

  Clear::SQL.init("postgres://postgres@localhost/clear_spec")
end

initdb

# module SpecHelper
#   class SetupDatabase1
#     include Clear::Migration

#     def change(dir)
#     end
#   end
# end

# Clear::Migration::Manager.instance.apply_all!
