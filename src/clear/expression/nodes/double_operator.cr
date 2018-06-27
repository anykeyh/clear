require "./node"

class Clear::Expression::Node::DoubleOperator < Clear::Expression::Node
  def initialize(@a : Node, @b : Node, @op : String); end

  def resolve
    {"(", @a.resolve, " ", @op, " ", @b.resolve, ")"}.join
  end
end
