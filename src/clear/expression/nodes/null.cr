require "./node"

# Render NULL !
class Clear::Expression::Node::Null < Clear::Expression::Node
  def initialize
  end

  def resolve : String
    "NULL"
  end
end
