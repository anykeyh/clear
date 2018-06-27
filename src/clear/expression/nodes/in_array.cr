require "./node"

class Clear::Expression::Node::InArray < Clear::Expression::Node
  def initialize(@target : Node, @array : Array(String)); end

  def resolve
    if @array.size == 0
      "FALSE" # If array is empty, return "FALSE" expression
    else
      {@target.resolve, " IN (", @array.join(", "), ")"}.join
    end
  end
end
