require "./node"

class Clear::Expression::Node::Literal < Clear::Expression::Node
  getter value : AvailableLiteral

  def initialize(@value : AvailableLiteral)
  end

  def resolve : String
    Clear::Expression[@value]
  end
end
