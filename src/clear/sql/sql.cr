require "../expression/expression"

require "pg"
require "db"

require "./errors"
require "./logger"

module Clear
  #
  # ## Clear::SQL
  #
  # Clear is made like an onion:
  #
  # ```
  # +------------------------------------+
  # |           THE ORM STACK            +
  # +------------------------------------+
  # |  Model | DB Views | Migrations     | < High Level Tools
  # +---------------+--------------------+
  # |  Field | Validation | Converters   | < Mapping system
  # +---------------+--------------------+
  # |  Clear::SQL   | Clear::Expression  | < Low Level SQL Builder
  # +------------------------------------+
  # |  Crystal DB   | Crystal PG         | < Low Level connection
  # +------------------------------------+
  # ```
  # On the bottom stack, Clear offer SQL query building.
  # Theses features are then used by uppermost parts of the engine.
  #
  # The SQL module provide simple API to generate delete, insert, select and update
  # methods.
  #
  # Each requests can be duplicated then modified and executed.
  #
  # Each request object is mutable. Therefor, to update and store a request,
  # you must use manually the `dup` method.
  #
  module SQL
    alias Any = Array(PG::BoolArray) | Array(PG::CharArray) | Array(PG::Float32Array) |
                Array(PG::Float64Array) | Array(PG::Int16Array) | Array(PG::Int32Array) |
                Array(PG::Int64Array) | Array(PG::StringArray) | Bool | Char | Float32 |
                Float64 | Int16 | Int32 | Int64 | JSON::Any | PG::Geo::Box | PG::Geo::Circle |
                PG::Geo::Line | PG::Geo::LineSegment | PG::Geo::Path | PG::Geo::Point |
                PG::Geo::Polygon | PG::Numeric | Slice(UInt8) | String | Time | UInt32 | Nil

    include Clear::SQL::Logger
    extend self

    class_getter! connection : DB::Database

    alias Symbolic = String | Symbol
    alias Selectable = Symbolic | Clear::SQL::SelectQuery

    # Sanitize the
    def sanitize(x : String, delimiter = "''")
      Clear::Expression[x]
    end

    def init(url : String)
      @@connection = DB.open(url)
    end

    def transaction(&block)
      execute("BEGIN")
      begin
        yield
        execute("COMMIT")
      rescue e
        execute("ROLLBACK") rescue nil
        raise e
      end
    end

    # Execute a SQL request.
    #
    # Usage:
    # Clear::SQL.execute("SELECT 1 FROM users")
    #
    def execute(sql)
      begin
        log_query(sql) { Clear::SQL.connection.exec(sql) }
      rescue e
        raise ExecutionError.new("Error while trying to execute SQL: `#{e.message}`\n" +
                                 "`#{Clear::SQL::Logger.colorize_query(sql)}`")
      end
    end

    def sel_str(s : Selectable)
      s.is_a?(Symbolic) ? s.to_s : s.to_sql
    end

    def delete(from = nil)
      Clear::SQL::DeleteQuery.new(from: from)
    end

    def insert(table, *args)
      insert_into(table, *args)
    end

    def insert_into(table, *args)
      Clear::SQL::InsertQuery.new(table).insert(*args)
    end

    def update(table)
      Clear::SQL::UpdateQuery.new(table)
    end

    def select(*args)
      if args.size > 0
        Clear::SQL::SelectQuery.new.select(*args)
      else
        Clear::SQL::SelectQuery.new
      end
    end
  end
end

require "./select_query"
require "./delete_query"
require "./insert_query"
require "./update_query"

require "./fragment/*"
