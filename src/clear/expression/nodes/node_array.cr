require "./node"

# This node is used to generate expression like `( a AND b AND ... AND k )`
class Clear::Expression::Node::NodeArray < Clear::Expression::Node
  property expression : Array(Node)
  property link : String

  def initialize(expression : Array(Node), @link)
    @expression = expression.dup
  end

  def resolve : String
    if @expression.any?
      {
        "(",
        @expression.join(" #{@link} ", &.resolve),
        ")",
      }.join
    else
      ""
    end
  end
end
