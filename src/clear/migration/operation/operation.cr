module Clear::Migration
  abstract struct Operation
    abstract def up : String?
    abstract def down : String?
  end
end

require "./*"
