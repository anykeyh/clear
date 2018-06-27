require "./node"

class Clear::Expression::Node::Not < Clear::Expression::Node
  def initialize(@a : Node); end

  def resolve
    {"NOT ", @a.resolve}.join
  end
end
