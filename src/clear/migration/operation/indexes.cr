module Clear::Migration
  class CreateIndex < Operation
    @name : String
    @table : String
    @fields : Array(String)
    @unique : Bool
    @using : String?

    def initialize(@table, @fields : Array(String), name = nil, @using = nil, @unique = false)
      @name = name || safe_name(table + "_" + fields.map(&.to_s.underscore).join("_") + "_idx")
    end

    def initialize(@table, field : String | Symbol, name = nil, @using = nil, @unique = false)
      @fields = [field]
      @name = name || safe_name([table, field.to_s.underscore].join("_") + "_idx")
    end

    def safe_name(x)
      x.gsub(/[^A-Za-z_0-9]/, "_")
    end

    private def print_unique
      @unique ? "UNIQUE" : nil
    end

    private def print_using
      @using ? "USING #{@using}" : nil
    end

    private def print_columns
      {"(", @fields.join(", "), ")"}.join
    end

    def up : Array(String)
      [["CREATE", print_unique, "INDEX", safe_name(@name), "ON", @table, print_using, print_columns].compact.join(" ")]
    end

    def down : Array(String)
      # Using of IF EXISTS in the case we have a migration with
      # column created followed by index. Dropping of the column
      # will cascade the deletion of the index, therefor the migration will
      # fail.
      ["DROP INDEX IF EXISTS #{@name}"]
    end
  end
end

module Clear::Migration::Helper
  # Add a column to a specific table
  def create_index(table, column, name = nil,
                   using = nil, unique = false)
    self.add_operation(Clear::Migration::CreateIndex.new(table, fields: [column], name: name,
      using: using, unique: unique))
  end

  def create_index(table, columns : Array(String), name = nil,
                   using = nil, unique = false)
    self.add_operation(Clear::Migration::CreateIndex.new(table, fields: columns, name: name,
      using: using, unique: unique))
  end
end
