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
                Array(PG::Int64Array) | Array(PG::StringArray) | Bool | Char | Float32 |
                Float64 | Int8 | Int16 | Int32 | Int64 | JSON::Any | JSON::Any::Type | PG::Geo::Box | PG::Geo::Circle |
                PG::Geo::Line | PG::Geo::LineSegment | PG::Geo::Path | PG::Geo::Point |
                PG::Geo::Polygon | PG::Numeric | Slice(UInt8) | String | Time |
                UInt8 | UInt16 | UInt32 | UInt64 | Clear::Expression::UnsafeSql | Nil

    include Clear::SQL::Logger
    extend self


    alias Symbolic = String | Symbol
    alias Selectable = Symbolic | Clear::SQL::SelectBuilder

    # Sanitize
    def sanitize(x : String, delimiter = "''")
      Clear::Expression[x]
    end

    # Escape the expression, double quoting it.
    #
    # It allows use of reserved keywords as table or column name
    def escape(x : String | Symbol)
      "\"" + x.to_s.gsub("\"", "\"\"") + "\""
    end

    def unsafe(x)
      Clear::Expression::UnsafeSql.new(x)
    end

    def init(url : String, connection_pool_size = 5)
      Clear::SQL::ConnectionPool.init(url, "default", connection_pool_size)
    end

    def init(name : String, url : String, connection_pool_size = 5)
      Clear::SQL::ConnectionPool.init(url, name, connection_pool_size)
      #@@connections[name] = DB.open(url)
    end

    def init(connections : Hash(Symbolic, String), connection_pool_size = 5)
      connections.each do |name, url|
        Clear::SQL::ConnectionPool.init(url, name, connection_pool_size)
      end
    end

    def add_connection(name : String, url : String, connection_pool_size = 5)
      Clear::SQL::ConnectionPool.init(url, name, connection_pool_size)
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
    def transaction(connection = "default", &block)
      Clear::SQL::ConnectionPool.with_connection(connection) do |cnx|
        has_rollback = false

        if @@in_transaction
          yield(cnx) # In case we already are in transaction, we just ignore
        else
          @@in_transaction = true
          execute("BEGIN")
          begin
            yield(cnx)
          rescue e
            has_rollback = true
            is_rollback_error = e.is_a?(RollbackError) || e.is_a?(CancelTransactionError)
            execute("ROLLBACK --" + (is_rollback_error ? "normal" : "program error")) rescue nil
            raise e unless is_rollback_error
          ensure
            execute("COMMIT") unless has_rollback
            @@in_transaction = false
          end
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
    def with_savepoint(connection_name = "default", &block)
      transaction do
        sp_name = "sp_#{@@savepoint_uid += 1}"
        begin
          execute(connection_name, "SAVEPOINT #{sp_name}")
          yield
          execute(connection_name, "RELEASE SAVEPOINT #{sp_name}") if in_transaction?
        rescue e : RollbackError
          execute(connection_name, "ROLLBACK TO SAVEPOINT #{sp_name}") if in_transaction?
        end
      end
    end

    # Raise a rollback, in case of transaction
    def rollback
      raise RollbackError.new
    end

    # Execute a SQL statement.
    #
    # Usage:
    # Clear::SQL.execute("SELECT 1 FROM users")
    #
    def execute(sql)
      log_query(sql) { Clear::SQL::ConnectionPool.with_connection("default", &.exec(sql)) }
    end

    # Execute a SQL statement on a specific connection.
    #
    # Usage:
    # Clear::SQL.execute("seconddatabase", "SELECT 1 FROM users")
    def execute(connection_name : String, sql)
      log_query(sql) do
        Clear::SQL::ConnectionPool.with_connection(connection_name, &.exec(sql))
      end
    end

    # :nodoc:
    def sel_str(s : Selectable)
      s.is_a?(Symbolic) ? s.to_s : s.to_sql
    end

    # Start a DELETE table query
    def delete(table = nil)
      Clear::SQL::DeleteQuery.new("default").from(table)
    end

    # Start a DELETE table query on specific connection
    def delete(connection : Symbolic, table = nil)
      Clear::SQL::DeleteQuery.new(connection).from(table)
    end

    # Start an INSERT INTO table query
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
