require "pg"
require "big_int"
require "big_float"

require "./query/*"

#
# An insert query
#
# cf. postgres documentation
# [ WITH [ RECURSIVE ] with_query [, ...] ]
# INSERT INTO table_name [ AS alias ] [ ( column_name [, ...] ) ]
#    { DEFAULT VALUES | VALUES ( { expression | DEFAULT } [, ...] ) [, ...] | query }
#    [ ON CONFLICT [ conflict_target ] conflict_action ]
#    [ RETURNING * | output_expression [ [ AS ] output_name ] [, ...] ]
#
#
#
#
class Clear::SQL::InsertQuery
  include Query::Change

  alias Inserable = ::Clear::SQL::Any | BigInt | BigFloat | Time
  getter keys : Array(Symbolic) = [] of Symbolic
  getter values : SelectQuery | Array(Array(Inserable)) = [] of Array(Inserable)
  getter table : Selectable
  getter returning : String?

  def initialize(@table : Selectable)
  end

  def fetch(&block : Hash(String, ::Clear::SQL::Any) -> Void)
    Clear::SQL.log_query to_sql do
      h = {} of String => ::Clear::SQL::Any

      Clear::SQL.connection.query(to_sql) do |rs|
        fetch_result_set(h, rs) { |x| yield(x) }
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

    return true
  ensure
    rs.close
  end

  def execute : Hash(String, ::Clear::SQL::Any)
    o = {} of String => ::Clear::SQL::Any

    if @returning.nil?
      Clear::SQL.execute(to_sql)
    else
      # return {} of String => ::Clear::SQL::Any
      fetch { |x| o = x; break }
    end

    o
  end

  # Fast insert system
  #
  # insert({field: "value"}).into(:table)
  #
  def insert(row : NamedTuple)
    @keys = row.keys.to_a.map(&.as(Symbolic))

    v = @values = [] of Array(Inserable)
    v << row.values.to_a.map(&.as(Inserable))

    change!
  end

  def insert(row : Hash(Symbolic, Inserable))
    @keys = row.keys.to_a.map(&.as(Symbolic))

    v = @values = [] of Array(Inserable)
    v << row.values.to_a.map(&.as(Inserable))

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
  def values(select_query : SelectQuery)
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
    @keys.any? ? "(" + @keys.map(&.to_s).join(", ") + ")" : nil
  end

  protected def print_values
    v = @values.as(Array(Array(Inserable)))
    v.map_with_index { |row, idx|
      raise QueryBuildingError.new "No value to insert (at row ##{idx})" if row.empty?

      "(" + row.map { |x| Clear::Expression[x] }.join(", ") + ")"
    }.join(",\n")
  end

  def to_sql
    raise QueryBuildingError.new "You must provide a `into` clause" if @table.nil?
    o = ["INSERT INTO", @table, print_keys]
    v = @values
    case v
    when SelectQuery
      o << "(" + v.to_sql + ")"
    else
      if v.empty? || (v.size == 1 && v[0].empty?) # < Case happening with model
        o << "DEFAULT VALUES"
      else
        o << "VALUES"
        o << print_values
      end
    end
    if @returning
      o << "RETURNING"
      o << @returning
    end

    o.compact.join(" ")
  end
end
