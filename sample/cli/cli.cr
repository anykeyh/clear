require "../../src/clear"

def initdb
  Clear::SQL.init("postgres://postgres@localhost/clear_spec")
end

initdb

class UpdatePasswordField3
  include Clear::Migration

  def change(dir)
    dir.up { puts "3:up" }
    dir.down { puts "3:down" }
  end
end

class CreateDatabase1
  include Clear::Migration

  def change(dir)
    dir.up { puts "1:up" }
    dir.down { puts "1:down" }
  end
end

class ApplyChange2
  include Clear::Migration

  def change(dir)
    dir.up { puts "2:up" }
    dir.down { puts "2:down" }
  end
end

Clear.seed do
  puts "This is a seed"
end

Clear.with_cli do
  puts "Usage: crystal sample/cli/cli.cr -- clear [args]"
end
