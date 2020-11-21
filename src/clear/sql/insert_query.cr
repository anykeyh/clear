require "pg"
require "big"

require "./query/*"

#
# An insert query
#
# cf. postgres documentation
# ```
# [ WITH [ RECURSIVE ] with_query [, ...] ]
# INSERT INTO table_name [ AS alias ] [ ( column_name [, ...] ) ]
#    { DEFAULT VALUES | VALUES ( { expression | DEFAULT } [, ...] ) [, ...] | query }
#    [ ON CONFLICT [ conflict_target ] conflict_action ]
#    [ RETURNING * | output_expression [ [ AS ] output_name ] [, ...] ]
# ```
#
#
#
#
class Clear::SQL::InsertQuery
  include Clear::SQL::Query::CTE
  include Query::Change
  include Query::Connection
  include Query::OnConflict

  alias Inserable = ::Clear::SQL::Any | BigInt | BigFloat | Time
  getter keys : Array(Symbolic) = [] of Symbolic
  getter values : SelectBuilder | Array(Array(Inserable)) = [] of Array(Inserable)
  getter! table : Symbol | String
  getter returning : String?

  def initialize(@table : Symbol | String)
  end

  def initialize(@table : Symbol | String, values)
    self.values(values)
  end

  def into(@table : Symbol | String)
  end

  def fetch(connection_name : String = "default", &block : Hash(String, ::Clear::SQL::Any) -> Nil)
    Clear::SQL.log_query to_sql do
      h = {} of String => ::Clear::SQL::Any

      Clear::SQL::ConnectionPool.with_connection(connection_name) do |cnx|
        cnx.query(to_sql) do |rs|
          fetch_result_set(h, rs) { |x| yield(x) }
        end
      end

    end
  end

  protected def fetch_result_set(h : Hash(String, ::Clear::SQL::Any), rs, &block) : Bool
    return false unless rs.move_next

    loop do
      rs.each_column do |col|
        h[col] = rs.read
      end

      yield(h)

      break unless rs.move_next
    end

    true
  ensure
    rs.close
  end

  def execute(connection_name : String = "default") : Hash(String, ::Clear::SQL::Any)
    o = {} of String => ::Clear::SQL::Any

    if @returning.nil?
      s = to_sql
      Clear::SQL.execute(connection_name, s)
    else
      # return {} of String => ::Clear::SQL::Any
      fetch(connection_name) { |x| o = x }
    end

    o
  end

  def clear_values
    @values = [] of Array(Inserable)
    change!
  end

  # Fast insert system
  #
  # insert({field: "value"}).into(:table)
  #
  def values(row : NamedTuple)
    @keys = row.keys.to_a.map(&.as(Symbolic))

    case v = @values
    when Array(Array(Inserable))
      v << row.values.to_a.map(&.as(Inserable))
    else #when SelectBuilder
      raise "Cannot insert both from SELECT query and from data"
    end

    change!
  end

  def values(row : Hash(Symbolic, Inserable))
    @keys = row.keys.to_a.map(&.as(Symbolic))

    case v = @values
    when Array(Array(Inserable))
      v << row.values.to_a.map(&.as(Inserable))
    else # when SelectBuilder
      raise "Cannot insert both from SELECT query and from data"
    end

    change!
  end

  def values(rows : Array(NamedTuple))
    rows.each do |nt|
      values(nt)
    end

    change!
  end

  def values(rows : Array(Hash(Symbolic, Inserable)))
    rows.each do |nt|
      values(nt)
    end

    change!
  end

  # Used with values
  def columns(*args)
    @keys = args

    change!
  end

  def values(*args)
    @values << args

    change!
  end

  # Insert into ... (...) SELECT
  def values(select_query : SelectBuilder)
    if @values.is_a?(Array) && @values.as(Array).any?
      raise QueryBuildingError.new "Cannot insert both from SELECT and from data"
    end

    @values = select_query

    change!
  end

  def returning(str : String)
    @returning = str

    change!
  end

  # Number of rows of this insertion request
  def size : Int32
    v = @values
    v.is_a?(Array) ? v.size : -1
  end

  protected def print_keys
    @keys.any? ? "(" + @keys.map { |x| Clear::SQL.escape(x.to_s) }.join(", ") + ")" : nil
  end

  protected def print_values
    v = @values.as(Array(Array(Inserable)))
    v.map_with_index { |row, idx|
      raise QueryBuildingError.new "No value to insert (at row ##{idx})" if row.empty?

      "(" + row.map { |x| Clear::Expression[x] }.join(", ") + ")"
    }.join(",\n")
  end

  def to_sql
    raise QueryBuildingError.new "You must provide a `into` clause" unless table = @table

    table = table.is_a?(Symbol) ? Clear::SQL.escape(table) : table

    o = [print_ctes, "INSERT INTO", table, print_keys]
    v = @values
    case v
    when SelectBuilder
      o << "(" + v.to_sql + ")"
    else
      if v.empty? || (v.size == 1 && v[0].empty?) # < Case happening with model
        o << "DEFAULT VALUES"
      else
        o << "VALUES"
        o << print_values
      end
    end

    print_on_conflict(o)

    if @returning
      o << "RETURNING"
      o << @returning
    end

    o.compact.join(" ")
  end
end
