module Clear::Migration
  abstract struct Operation
    abstract def up : Array(String)
    abstract def down : Array(String)
  end
end

require "./*"
