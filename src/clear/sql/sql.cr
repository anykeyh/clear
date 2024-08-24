require "../expression/expression"

require "pg"
require "db"

require "./errors"
require "./logger"
require "./transaction"

# Add a field to DB::Database to handle
#   the state of transaction of a specific
#   connection
abstract class DB::Connection
  # add getter to transaction status for this specific DB::Connection
  property? _clear_in_transaction : Bool = false
end

module Clear
  #
  # ## Clear::SQL
  #
  # Clear is made like an onion:
  #
  # ```text
  # +------------------------------------+
  # |           THE ORM STACK            +
  # +------------------------------------+
  # |  Model | DB Views | Migrations     | < High level things
  # +---------------+--------------------+
  # |  Columns | Validation | Converters | < Mapping stuff
  # +---------------+--------------------+
  # |  Clear::SQL   | Clear::Expression  | < Low level SQL builder
  # +------------------------------------+
  # |  Crystal DB   | Crystal PG         | < Libs we deal with
  # +------------------------------------+
  # ```
  #
  # On the bottom stack, Clear offer SQL query building.
  # Features provided are then used by top level parts of the engine.
  #
  # The SQL module provide a simple API to generate `delete`, `insert`, `select`
  # and `update` methods.
  #
  # Each requests can be duplicated then modified and executed.
  #
  # Note: Each request object is mutable. Therefore, to keep a request prior to modification,
  # you must use manually the `dup` method.
  module SQL
    alias Any = Array(PG::BoolArray) | Array(PG::CharArray) | Array(PG::Float32Array) |
                Array(PG::Float64Array) | Array(PG::Int16Array) | Array(PG::Int32Array) |
                Array(PG::Int64Array) | Array(PG::StringArray) | Array(PG::TimeArray) |
                Array(PG::NumericArray) | Array(PG::UUIDArray) |
                Bool | Char | Float32 | Float64 | Int8 | Int16 | Int32 | Int64 | BigDecimal | JSON::PullParser | JSON::Any | JSON::Any::Type | PG::Geo::Box | PG::Geo::Circle |
                PG::Geo::Line | PG::Geo::LineSegment | PG::Geo::Path | PG::Geo::Point |
                PG::Geo::Polygon | PG::Numeric | PG::Interval | Slice(UInt8) | String | Time |
                UInt8 | UInt16 | UInt32 | UInt64 | Clear::Expression::UnsafeSql | UUID |
                Nil

    include Clear::SQL::Logger
    include Clear::SQL::Transaction
    extend self

    alias Symbolic = String | Symbol
    alias Selectable = Symbolic | Clear::SQL::SelectBuilder

    # Sanitize string and convert some literals (e.g. `Time`)
    def sanitize(x)
      Clear::Expression[x]
    end

    # This provide a fast way to create SQL fragment while escaping items, both with `?` and `:key` system:
    #
    # ```
    # query = Mode.query.select(Clear::SQL.raw("CASE WHEN x=:x THEN 1 ELSE 0 END as check", x: "blabla"))
    # query = Mode.query.select(Clear::SQL.raw("CASE WHEN x=? THEN 1 ELSE 0 END as check", "blabla"))
    # ```
    #
    # note than returned string is tagged as unsafe and SQL inject is possible (so beware!)
    def raw(__template, *__args)
      __args.size > 0 ? Clear::Expression.raw(__template, *__args) : __template
    end

    # :ditto:
    def raw(__template, **__keys)
      __keys.size > 0 ? Clear::Expression.raw(__template, **__keys) : __template
    end

    # Escape the expression, double quoting it.
    #
    # It allows use of reserved keywords as table or column name
    # NOTE: Escape is used for escaping postgresql keyword. For example
    # if you have a column named order (which is a reserved word), you want
    # to escape it by double-quoting it.
    #
    # For escaping STRING value, please use Clear::SQL.sanitize
    def escape(x : String | Symbol)
      "\"" + x.to_s.gsub("\"", "\"\"") + "\""
    end

    # Create an unsafe expression, which can be used in many places in Clear as
    # substitute for string
    #
    # ```
    #   select.where("x = ?", Clear::SQL.unsafe("y")) # SELECT ... WHERE x = y
    # ```
    def unsafe(x)
      Clear::Expression::UnsafeSql.new(x)
    end

    # Initialize a new connection to a specific database
    # Use "default" connection if no name is provided:
    # ```
    # init("postgres://postgres@localhost:5432/database") # use "default" connection
    # init("secondary_db", "postgres://postgres@localhost:5432/secondary_db")
    # ```
    def init(url : String)
      Clear::SQL::ConnectionPool.init(url, "default")
    end

    # :ditto:
    def init(name : String, url : String)
      Clear::SQL::ConnectionPool.init(url, name)
    end

    # connect through a hash/named tuple of connections:
    #
    # ```
    # Clear::SQL.init(
    #   default: "postgres://postgres@localhost:5432/database",
    #   secondary: "postgres://postgres@localhost:5432/secondary"
    # )
    # ```
    def init(**__named_tuple)
      init(__named_tuple.to_h)
    end

    # :ditto:
    def init(connections : Hash(Symbolic, String))
      connections.each do |name, url|
        add_connection(name, url)
      end
    end

    # :ditto:
    def add_connection(name : String, url : String)
      Clear::SQL::ConnectionPool.init(url, name)
    end

    # Execute a SQL statement without returning a result set
    #
    # Usage:
    #
    # ```
    # Clear::SQL.execute("NOTIFY listener")
    # ```
    #
    def execute(connection_name : String, sql)
      log_query(sql) { Clear::SQL::ConnectionPool.with_connection(connection_name, &.exec_all(sql)) }
    end

    # :ditto:
    def execute(sql : String)
      execute("default", sql)
    end

    # :nodoc:
    def sel_str(s : Selectable)
      s.is_a?(Symbolic) ? s.to_s : s.to_sql
    end

    # Prepare a DELETE table query
    def delete(table : Symbolic)
      Clear::SQL::DeleteQuery.new.from(table)
    end

    # Start an INSERT INTO table query
    #
    # ```
    # Clear::SQL.insert_into("table", {id: 1, name: "hello"}, {id: 2, name: "World"})
    # ```
    def insert_into(table : Symbolic, *args)
      Clear::SQL::InsertQuery.new(table).values(*args)
    end

    # Prepare a new INSERT INTO table query
    # :ditto:
    def insert_into(table : Symbolic)
      Clear::SQL::InsertQuery.new(table)
    end

    # Alias of `insert_into`, for developers in hurry
    # :ditto:
    def insert(table : Symbolic, *args)
      insert_into(table, *args)
    end

    # :ditto:
    def insert(table : Symbolic, args : NamedTuple)
      insert_into(table, args)
    end

    # Create a new blank INSERT query. See `Clear::SQL::InsertQuery`
    def insert
      Clear::SQL::InsertQuery.new
    end

    # Start a UPDATE table query. See `Clear::SQL::UpdateQuery`
    def update(table : Symbolic)
      Clear::SQL::UpdateQuery.new(table)
    end

    # Start a SELECT ... query
    def select(*args)
      if args.size > 0
        Clear::SQL::SelectQuery.new.select(*args)
      else
        Clear::SQL::SelectQuery.new
      end
    end

    # :ditto:
    def select(**args)
      Clear::SQL::SelectQuery.new.select(**args)
    end
  end
end

require "./select_query"
require "./delete_query"
require "./insert_query"
require "./update_query"

require "./fragment/*"
