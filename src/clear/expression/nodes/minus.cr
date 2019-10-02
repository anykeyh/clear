require "./node"

# A node managing the unary `-` operator.
class Clear::Expression::Node::Minus < Clear::Expression::Node
  def initialize(@a : Node); end

  def resolve : String
    {"-", @a.resolve}.join
  end
end
