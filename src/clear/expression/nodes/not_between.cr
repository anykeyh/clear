require "./node"

# A node managing the rendering of `(var NOT BETWEEN a AND b)`
# expressions.
class Clear::Expression::Node::NotBetween < Clear::Expression::Node
  alias BetweenType = Int32 | Int64 | Float32 | Float64 | String | Time | Node

  def initialize(@target : Node, @starts : BetweenType, @ends : BetweenType)
  end

  def resolve : String
    {
      "(",
      @target.resolve,
      " NOT BETWEEN ",
      Clear::Expression[@starts],
      " AND ",
      Clear::Expression[@ends],
      ")",
    }.join
  end
end
