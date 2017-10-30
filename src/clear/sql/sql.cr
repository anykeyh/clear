require "../expression/expression"

require "pg"
require "db"

require "colorize"
require "logger"
require "benchmark"

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

    class Error < Exception; end

    class QueryBuildingError < Error; end

    extend self

    class_property logger : Logger = Logger.new(STDOUT)

    logger.level = Logger::DEBUG

    class_getter connection : DB::Database = DB.open("postgres://postgres@localhost/otc_development_master")

    alias Symbolic = String | Symbol
    alias Selectable = Symbolic | Clear::SQL::SelectQuery

    # Sanitize the
    def sanitize(x : String, delimiter = "''")
      Clear::Expression[x]
    end

    # Execute a SQL request.
    #
    # Usage:
    # Clear::SQL.execute("SELECT 1 FROM users")
    #
    def execute(sql)
      log_query(sql) { Clear::SQL.connection.exec(sql) }
    end

    # FIXME: This is a helper, we should export it somewhere else
    SQL_KEYWORDS = %w(
      ALL ANALYSE ANALYZE AND ANY ARRAY AS ASC ASYMMETRIC
      BOTH CASE CAST CHECK COLLATE COLUMN CONSTRAINT CREATE
      CURRENT_DATE CURRENT_ROLE CURRENT_TIME CURRENT_TIMESTAMP
      CURRENT_USER DEFAULT DEFERRABLE DESC DISTINCT DO ELSE
      END EXCEPT FALSE FOR FOREIGN FROM GRANT GROUP HAVING IN
      INITIALLY INTERSECT INTO LEADING LIMIT LOCALTIME LOCALTIMESTAMP
      NEW NOT NULL OFF OFFSET OLD ON ONLY OR ORDER PLACING PRIMARY
      REFERENCES SELECT SESSION_USER SOME SYMMETRIC TABLE THEN TO
      TRAILING TRUE UNION UNIQUE USER USING WHEN WHERE
    )

    def colorize_query(qry : String)
      qry.to_s.split(/ /).map do |word|
        if SQL_KEYWORDS.includes?(word.upcase)
          word.colorize.bold.blue.to_s
        elsif word =~ /\d+/
          word.colorize.red
        else
          word.colorize.dark_gray
        end
      end.join(" ")
    end

    # FIXME: This is a helper, we should export it somewhere else
    def self.display_time(x)
      if (x > 1)
        x.to_i.to_s + "s"
      elsif (x > 0.001)
        (1000*x).to_i.to_s + "ms"
      else
        (1000000*x).to_i.to_s + "µs"
      end
    end

    def log_query(sql, &block)
      time = Time.now.epoch_f # TODO: Change to Time.monotonic
      yield
    ensure
      time = Time.now.epoch_f - time.not_nil!
      logger.debug(("[" + SQL.display_time(time).colorize.bold.white.to_s + "] #{colorize_query(sql)}"))
    end

    def sel_str(s : Selectable)
      s.is_a?(Symbolic) ? s.to_s : s.to_sql
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
