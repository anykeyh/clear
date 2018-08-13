require "./node"

# Raw unsafe SQL fragment.
class Clear::Expression::Node::Raw < Clear::Expression::Node
  def initialize(@raw : String); end

  def resolve
    @raw
  end
end
