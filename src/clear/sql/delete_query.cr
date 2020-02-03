require "./query/*"

class Clear::SQL::DeleteQuery
  getter table : Symbolic?

  include Query::Connection
  include Query::Where
  include Query::Execute
  include Query::Change

  def initialize(@table = nil, @wheres = [] of Clear::Expression::Node)
  end

  def from(table)
    @table = table
    change!
  end

  def to_sql
    raise Clear::ErrorMessages.query_building_error("Delete Query must have a `from` clause.") unless table = @table

    table = table.is_a?(Symbol) ? SQL.escape(table.to_s) : table

    ["DELETE FROM", table, print_wheres].compact.join(" ")
  end
end
