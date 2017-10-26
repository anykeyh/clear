module Clear::Migration
  struct CreateIndex < Operation
    @name : String
    @table : String
    @fields : Array(String)
    @unique : Bool
    @using : String?

    def initialize(@table, fields : Array(T), name = nil, @using = nil, @unique = false) forall T
      @fields = fields.map(&.to_s.underscore)
      @name = name || (table + "_" + fields.map(&.to_s.underscore).join("_") + "_idx")
    end

    def initialize(@table, field : String | Symbol, name = nil, @using = nil, @unique = false)
      @fields = [field]
      @name = name || [table, field.to_s.underscore].join("_") + "_idx"
    end

    private def print_unique
      @unique ? "UNIQUE" : nil
    end

    private def print_using
      @using ? "USING #{@using}" : nil
    end

    private def print_columns
      "(" + @fields.join(", ") + ")"
    end

    def up
      ["CREATE", print_unique, "INDEX", @name, "ON", @table, print_using, print_columns].compact.join(" ")
    end

    def down
      "DROP INDEX #{@name}"
    end
  end

  struct DropIndex < Operation
    def initialize(@table)
    end

    def up
      "DROP TABLE #{@table}"
    end

    def down
      "CREATE TABLE #{@table}"
    end
  end
end
