require "./node"

class Clear::Expression::Node::Minus < Clear::Expression::Node
  def initialize(@a : Node); end

  def resolve
    "-#{@a.resolve}"
  end
end
