###
# A simple NULL node.
#
class Clear::Expression::Node::Null < Clear::Expression::Node
  def initialize
  end

  def resolve
    "NULL"
  end
end
