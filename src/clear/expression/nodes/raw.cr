require "./node"

# This node manage the rendering of a raw SQL fragment.
class Clear::Expression::Node::Raw < Clear::Expression::Node
  def initialize(@raw : String); end

  def resolve : String
    @raw
  end
end
