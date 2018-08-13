require "./query/*"

class Clear::SQL::DeleteQuery
  getter from : Symbolic?

  include Query::Connection
  include Query::Where
  include Query::Execute
  include Query::Change

  def initialize(@from = nil,
                 @wheres = [] of Clear::Expression::Node)
  end

  def from(x)
    @from = x
    change!
  end

  def to_sql
    raise Clear::ErrorMessages.query_building_error("Delete Query must have a `from` clause.") unless from = @from

    from = from.is_a?(Symbol) ? SQL.escape(from.to_s) : from

    ["DELETE FROM", from, print_wheres].compact.join(" ")
  end
end
