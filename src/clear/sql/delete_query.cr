require "./query/*"

class Clear::SQL::DeleteQuery
  getter from : Symbolic?

  include Query::Where

  def initialize(@from = nil,
                 @wheres = [] of Clear::Expression::Node)
  end

  def from(x)
    @from = x
    self
  end

  def to_sql
    raise QueryBuildingError.new("Delete Query must have a `from` clause.") if @from.nil?
    ["DELETE FROM #{@from}", print_wheres].compact.join(" ")
  end
end
