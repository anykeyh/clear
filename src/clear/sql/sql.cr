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
  # |  Model | DB Views | Migrations     | < High Level Tools
  # +---------------+--------------------+
  # |  Columns | Validation | Converters | < Mapping system
  # +---------------+--------------------+
  # |  Clear::SQL   | Clear::Expression  | < Low Level SQL Builder
  # +------------------------------------+
  # |  Crystal DB   | Crystal PG         | < Low Level connection
  # +------------------------------------+
  # ```
  #
  # On the bottom stack, Clear offer SQL query building.
  # Theses features are then used by top level parts of the engine.
  #
  # The SQL module provide a simple API to generate `delete`, `insert`, `select`
  # and `update` methods.
  #
  # Each requests can be duplicated then modified and executed.
  #
  # Note: Each request object is mutable. Therefore, to update and store a request,
  # you must use manually the `dup` method.
  #
  module SQL
    alias Any = Array(PG::BoolArray) | Array(PG::CharArray) | Array(PG::Float32Array) |
                Array(PG::Float64Array) | Array(PG::Int16Array) | Array(PG::Int32Array) |
                Array(PG::Int64Array) | Array(PG::StringArray) | Array(PG::TimeArray) |
                Array(PG::NumericArray) |
                Bool | Char | Float32 | Float64 | Int8 | Int16 | Int32 | Int64 | JSON::Any | JSON::Any::Type | PG::Geo::Box | PG::Geo::Circle |
                PG::Geo::Line | PG::Geo::LineSegment | PG::Geo::Path | PG::Geo::Point |
                PG::Geo::Polygon | PG::Numeric | Slice(UInt8) | String | Time |
                UInt8 | UInt16 | UInt32 | UInt64 | Clear::Expression::UnsafeSql |
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
    # query = Mode.query.select( Clear::SQL.raw("CASE WHEN x=:x THEN 1 ELSE 0 END as check", x: "blabla") )
    # query = Mode.query.select( Clear::SQL.raw("CASE WHEN x=? THEN 1 ELSE 0 END as check", "blabla") )
    # ```
    def raw(__template, *__args)
      __args.size > 0 ? Clear::Expression.raw(__template, *__args) : __template
    end

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

    def unsafe(x)
      Clear::Expression::UnsafeSql.new(x)
    end

    def init(url : String)
      Clear::SQL::ConnectionPool.init(url, "default")
    end

    def init(name : String, url : String)
      Clear::SQL::ConnectionPool.init(url, name)
    end

    def init(connections : Hash(Symbolic, String))
      connections.each do |name, url|
        Clear::SQL::ConnectionPool.init(url, name)
      end
    end

    def add_connection(name : String, url : String)
      Clear::SQL::ConnectionPool.init(url, name)
    end

    # Truncate a table or a model
    #
    # ```
    #   User.query.count # => 200
    #   Clear::SQL.truncate(User) # equivalent to Clear::SQL.truncate(User.table, connection_name: User.connection)
    #   User.query.count # => 0
    # ```
    #
    # SEE https://www.postgresql.org/docs/current/sql-truncate.html
    # for more information.
    #
    # - `restart_sequence` set to true will append `RESTART IDENTITY` to the query
    # - `cascade` set to true will append `CASCADE` to the query
    # - `truncate_inherited` set to false will append `ONLY` to the query
    # - `connection_name` will be: `Model.connection` or `default` unless optionally defined.
    def self.truncate(tablename : T.class | String, restart_sequence = false, cascade = false, truncate_inherited = true, connection_name : String? = nil) forall T
      if(tablename.is_a?(String))
        connection_name ||= "default"
      else
        connection_name ||= tablename.connection
        tablename ||= tablename.table
      end

      only = truncate_inherited ? "" : " ONLY "
      restart_sequence = restart_sequence ? " RESTART IDENTITY " : ""
      cascade = cascade ? " CASCADE " : ""

      execute(connection_name,
        {"TRUNCATE TABLE ", only, Clear::SQL.escape(tablename), restart_sequence, cascade }.join
      )
    end

    # Execute a SQL statement.
    #
    # Usage:
    # Clear::SQL.execute("SELECT 1 FROM users")
    #
    def execute(sql)
      execute("default", sql)
    end

    # Execute a SQL statement on a specific connection.
    #
    # Usage:
    # Clear::SQL.execute("seconddatabase", "SELECT 1 FROM users")
    def execute(connection_name : String, sql)
      log_query(sql){ Clear::SQL::ConnectionPool.with_connection(connection_name, &.exec_all(sql)) }
    end

    # :nodoc:
    def sel_str(s : Selectable)
      s.is_a?(Symbolic) ? s.to_s : s.to_sql
    end

    # Start a DELETE table query
    def delete(table : Symbolic)
      Clear::SQL::DeleteQuery.new.from(table)
    end

    # Prepare a new INSERT INTO table query
    def insert_into(table)
      Clear::SQL::InsertQuery.new(table)
    end

    # Start an INSERT INTO table query
    #
    # ```
    # Clear::SQL.insert_into("table", id: 1, name: "hello")
    # ```
    def insert_into(table, *args)
      Clear::SQL::InsertQuery.new(table).values(*args)
    end

    # Create a new INSERT query
    def insert
      Clear::SQL::InsertQuery.new
    end

    # Alias of `insert_into`, for hurry developers
    def insert(table, *args)
      insert_into(table, *args)
    end

    def insert(table, args : NamedTuple)
      insert_into(table, args)
    end

    # Start a UPDATE table query
    def update(table)
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

    # Start a SELECT ... query
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
