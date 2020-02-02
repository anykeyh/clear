require "./node"

# This node is used to generate expression like `( a AND b AND ... AND k )`
class Clear::Expression::Node::AndArray < Clear::Expression::Node
  @expression : Array(Node)

  def initialize(expression : Array(Node))
    @expression = expression.dup
  end

  def resolve : String
    if @expression.any?
      {
        "(",
        @expression.map(&.resolve).join(" AND "),
        ")"
      }.join
    else
      ""
    end
  end
end