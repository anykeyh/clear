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
  # ```text
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
  #
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
                Float64 | Int8 | Int16 | Int32 | Int64 | JSON::Any | PG::Geo::Box | PG::Geo::Circle |
                PG::Geo::Line | PG::Geo::LineSegment | PG::Geo::Path | PG::Geo::Point |
                PG::Geo::Polygon | PG::Numeric | Slice(UInt8) | String | Time |
                UInt8 | UInt16 | UInt32 | UInt64 | Clear::Expression::UnsafeSql | Nil

    include Clear::SQL::Logger
    extend self

    @@connections = {} of String => DB::Database

    def self.connection(connection) : DB::Database
      @@connections[connection]? || raise "The database connection " +
                                          "`#{connection}` is not initialized"
    end

    alias Symbolic = String | Symbol
    alias Selectable = Symbolic | Clear::SQL::SelectBuilder

    # Sanitize the
    def sanitize(x : String, delimiter = "''")
      Clear::Expression[x]
    end

    def init(url : String)
      @@connections["default"] = DB.open(url)
    end

    def init(name : String, url : String)
      @@connections[name] = DB.open(url)
    end

    def init(connections : Hash(Symbolic, String))
      connections.each do |name, url|
        @@connections[name.to_s] = DB.open(url)
      end
    end

    @@in_transaction : Bool = false
    @@savepoint_uid : UInt64 = 0_u64

    def in_transaction?
      @@in_transaction
    end

    # Create an unstackable transaction
    #
    # Example:
    # ```
    # Clear::SQL.transaction do
    #   # do something
    #   Clear::SQL.transaction do # Technically, this block do nothing, since we already are in transaction
    #     rollback                # < Rollback the up-most `transaction` block.
    #   end
    # end
    # ```
    # see #with_savepoint to use a stackable version using savepoints.
    #
    def transaction(&block)
      if @@in_transaction
        yield # In case we already are in transaction, we just ignore
      else
        @@in_transaction = true
        execute("BEGIN")
        begin
          yield
          execute("COMMIT")
        rescue e
          is_rollback_error = e.is_a?(RollbackError) || e.is_a?(CancelTransactionError)
          execute("ROLLBACK --" + (is_rollback_error ? "normal" : "program error")) rescue nil
          raise e unless is_rollback_error
        ensure
          @@in_transaction = false
        end
      end
    end

    # Create a transaction, but this one is stackable
    # using savepoints.
    #
    # Example:
    # ```
    # Clear::SQL.with_savepoint do
    #   # do something
    #   Clear::SQL.with_savepoint do
    #     rollback # < Rollback only the last `with_savepoint` block
    #   end
    # end
    # ```
    def with_savepoint(&block)
      transaction do
        sp_name = "sp_#{@@savepoint_uid += 1}"
        begin
          execute("SAVEPOINT #{sp_name}")
          yield
          execute("RELEASE SAVEPOINT #{sp_name}")
        rescue e : RollbackError
          execute("ROLLBACK TO SAVEPOINT #{sp_name}")
        end
      end
    end

    # Raise a rollback, in case of transaction
    def rollback
      raise RollbackError.new
    end

    # Execute a SQL request.
    #
    # Usage:
    # Clear::SQL.execute("SELECT 1 FROM users")
    #
    def execute(sql)
      log_query(sql) { Clear::SQL.connection("default").exec(sql) }
    end

    # Execute a SQL request on a specific connection.
    #
    # Usage:
    # Clear::SQL.execute("seconddatabase", "SELECT 1 FROM users")
    def execute(connection_name : String, sql)
      log_query(sql) { Clear::SQL.connection(connection_name).exec(sql) }
    end

    # :nodoc:
    def sel_str(s : Selectable)
      s.is_a?(Symbolic) ? s.to_s : s.to_sql
    end

    # Start a DELETE table query
    def delete(table = nil)
      Clear::SQL::DeleteQuery.new("default").from(table)
    end

    def delete(connection : Symbolic, table = nil)
      Clear::SQL::DeleteQuery.new(connection).from(table)
    end

    # Start an INSERT INTO table query
    def insert_into(table, *args)
      Clear::SQL::InsertQuery.new(table).insert(*args)
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

    # Start a SELECT FROM table query
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
