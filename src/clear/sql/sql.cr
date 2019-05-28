require "../expression/expression"

require "pg"
require "db"

require "./errors"
require "./logger"

# Add a field to DB::Database to handle
#   the state of transaction of a specific
#   connection
abstract class DB::Database
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
                Array(PG::Int64Array) | Array(PG::StringArray) | Bool | Char | Float32 |
                Float64 | Int8 | Int16 | Int32 | Int64 | JSON::Any | JSON::Any::Type | PG::Geo::Box | PG::Geo::Circle |
                PG::Geo::Line | PG::Geo::LineSegment | PG::Geo::Path | PG::Geo::Point |
                PG::Geo::Polygon | PG::Numeric | Slice(UInt8) | String | Time |
                UInt8 | UInt16 | UInt32 | UInt64 | Clear::Expression::UnsafeSql | Nil

    include Clear::SQL::Logger
    extend self

    alias Symbolic = String | Symbol
    alias Selectable = Symbolic | Clear::SQL::SelectBuilder

    # Sanitize string and convert some literals (e.g. `Time`)
    def sanitize(x)
      Clear::Expression[x]
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

    @@savepoint_uid : UInt64 = 0_u64

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

        if cnx._clear_in_transaction?
          return yield(cnx) # In case we already are in transaction, we just ignore
        else
          cnx._clear_in_transaction = true
          execute("BEGIN")
          begin
            return yield(cnx)
          rescue e
            has_rollback = true
            is_rollback_error = e.is_a?(RollbackError) || e.is_a?(CancelTransactionError)
            execute("ROLLBACK --" + (is_rollback_error ? "normal" : "program error")) rescue nil
            raise e unless is_rollback_error
          ensure
            cnx._clear_in_transaction = false
            execute("COMMIT") unless has_rollback
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
      transaction do |cnx|
        sp_name = "sp_#{@@savepoint_uid += 1}"
        begin
          execute(connection_name, "SAVEPOINT #{sp_name}")
          yield
          execute(connection_name, "RELEASE SAVEPOINT #{sp_name}") if cnx._clear_in_transaction?
        rescue e : RollbackError
          execute(connection_name, "ROLLBACK TO SAVEPOINT #{sp_name}") if cnx._clear_in_transaction?
        end
      end
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
