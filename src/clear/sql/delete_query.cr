require "./query/*"

class Clear::SQL::DeleteQuery
  getter from : Symbolic?

  include Query::Connection
  include Query::Where
  include Query::Execute
  include Query::Change

  def initialize(@from = nil,
                 @wheres = [] of Clear::Expression::Node)
    @connection = "default"
    @connection_name = "default"
  end

  def initialize(@connection : String,
                 @from = nil,
                 @wheres = [] of Clear::Expression::Node)
    @connection_name = @connection
  end

  def from(x)
    @from = x
    change!
  end

  def to_sql
    raise QueryBuildingError.new("Delete Query must have a `from` clause.") if @from.nil?
    ["DELETE FROM #{@from}", print_wheres].compact.join(" ")
  end
end
