require "./node"

# A node managing the rendering of array in Postgres.
# - It renders `val IN (...)`.
# - If the array passed as argument is empty, it renders `FALSE` instead.
class Clear::Expression::Node::InArray < Clear::Expression::Node
  def initialize(@target : Node, @array : Array(String)); end

  def resolve : String
    if @array.size == 0
      "FALSE" # If array is empty, return "FALSE" expression
    else
      {@target.resolve, " IN (", @array.join(", "), ")"}.join
    end
  end
end
