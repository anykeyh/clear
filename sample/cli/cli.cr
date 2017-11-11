require "../src/clear"

def initdb
  `echo "DROP DATABASE IF EXISTS clear_spec;" | psql -U postgres`
  `echo "CREATE DATABASE clear_spec;" | psql -U postgres`

  Clear::SQL.init("postgres://postgres@localhost/clear_spec")
end

initdb

class MyMigration1
  include Clear::Migration

  def change(dir)
    dir.up { puts "up!" }
    dir.down { puts "down!" }
  end
end

Clear::CLI.run
