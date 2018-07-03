module Clear::Migration
  struct CreateEnum < Operation
    @name : String
    @values : Array(String)

    def initialize(@name, @values)
    end

    def up
      ["CREATE TYPE #{@name} AS ENUM (#{Clear::Expression[@values].join(", ")})"]
    end

    def down
      ["DROP TYPE #{@name}"]
    end
  end

  module Clear::Migration::Helper
    def create_enum(name, e : T.class) forall T
      {% raise "Second parameter must inherits from Clear::Enum type" unless T < Clear::Enum %}
      self.add_operation(CreateEnum.new(name.to_s, e.authorized_values))
    end
  end
end
