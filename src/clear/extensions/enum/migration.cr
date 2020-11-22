
module Clear::Migration
  class CreateEnum < Operation
    @name : String
    @values : Array(String)

    def initialize(@name : String, @values : Array(String))
    end

    def up : Array(String)
      safe_values = @values.map{ |v| Clear::Expression[v] }
      ["CREATE TYPE #{@name} AS ENUM (#{safe_values.join(", ")})"]
    end

    def down : Array(String)
      ["DROP TYPE #{@name}"]
    end
  end

  class DropEnum < Operation
    @name : String
    @values : Array(String)?

    def initialize(@name : String, @values : Array(String)?)
    end

    def up : Array(String)
      ["DROP TYPE #{@name}"]
    end

    def down : Array(String)
      if values = @values
        safe_values = values.map{ |v| Clear::Expression[v] }
        ["CREATE TYPE #{@name} AS ENUM (#{safe_values.join(", ")})"]
      else
        irreversible!
      end
    end

  end

  module Clear::Migration::Helper
    def create_enum(name : Clear::SQL::Symbolic, arr : Enumerable(T)) forall T
      self.add_operation(CreateEnum.new(name.to_s, arr.map(&.to_s) ))
    end

    def drop_enum(name : Clear::SQL::Symbolic, arr : Enumerable(T)? = nil ) forall T
      self.add_operation( DropEnum.new(name.to_s, arr.try &.map(&.to_s)) )
    end

    def create_enum(name : Clear::SQL::Symbolic, e : ::Clear::Enum.class )
      self.add_operation(CreateEnum.new(name.to_s, e.authorized_values))
    end
  end
end
