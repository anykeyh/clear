require "./node"

class Clear::Expression::Node::Literal < Clear::Expression::Node
  def initialize(@lit : AvailableLiteral)
  end

  def resolve : String
    Clear::Expression[@lit]
  end
end
