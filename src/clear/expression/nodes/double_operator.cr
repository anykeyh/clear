require "./node"

# A node managing the rendering of
# combination operations like `<val1> <op> <val2>`
class Clear::Expression::Node::DoubleOperator < Clear::Expression::Node
  def initialize(@a : Node, @b : Node, @op : String); end

  def resolve : String
    {"(", @a.resolve, " ", @op, " ", @b.resolve, ")"}.join
  end
end
