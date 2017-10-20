require "big_int"
require "big_float"

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
  alias Inserable = String | Time | Int32 | Int64 | Float32 | Float64 |
                    BigInt | BigFloat
  @keys : Array(Symbolic) = [] of Symbolic
  @values : SelectQuery | Array(Array(Inserable)) = [] of Array(Inserable)
  @table : Selectable

  def initialize(@table : Selectable)
  end

  # Fast insert system
  #
  # insert({field: "value"}).into(:table)
  #
  def insert(row : NamedTuple)
    @keys = row.keys.to_a.map(&.as(Symbolic))

    v = @values = [] of Array(Inserable)
    v << row.values.to_a.map(&.as(Inserable))

    self
  end

  # Used with values
  def columns(*args)
    @keys = args

    self
  end

  def values(*args)
    @values << args

    self
  end

  # Insert into ... (...) SELECT
  def values(select_query : SelectQuery)
    if @values.is_a?(Array) && @values.as(Array).any?
      raise QueryBuildingError.new "Cannot insert both from SELECT and from data"
    end

    @values = select_query

    self
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
      o << "VALUES"
      o << print_values
    end

    o.compact.join(" ")
  end
end
