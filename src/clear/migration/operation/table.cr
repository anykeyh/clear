module Clear::Migration
  class Table
  end

  struct AddTable < Operation
    def initialize(@table)
    end

    def up
      "CREATE TABLE #{@table}"
    end

    def down
      "DROP TABLE #{@table}"
    end
  end

  struct DropTable < Operation
    def initialize(@table)
    end

    def up
      "DROP TABLE #{@table}"
    end

    def down
      "CREATE TABLE #{@table}"
    end
  end

  module Helper
    # Add a column to a specific table
    def create_table(name, &block)
      table = Table.new(name)
      with table yield

      self.add_operation(table.to_operation)
    end
  end
end
