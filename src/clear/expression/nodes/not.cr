require "./node"

# A node managing the unary `NOT` operator.
class Clear::Expression::Node::Not < Clear::Expression::Node
  def initialize(@a : Node); end

  def resolve : String
    {"NOT ", @a.resolve}.join
  end
end
