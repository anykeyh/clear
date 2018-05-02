require "./node"

class Clear::Expression::Node::InArray < Clear::Expression::Node
  def initialize(@target : Node, @array : Array(Literal)); end

  def resolve
    if @array.size == 0
      "FALSE" # Cannot be in empty :o
    else
      "#{@target.resolve} IN (#{@array.map { |x| x.resolve }.join(", ")})"
    end
  end
end
