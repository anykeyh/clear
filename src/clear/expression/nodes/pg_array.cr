require "./node"

# A node managing PG structure `array[args...]`
# Named PGArray instead of Array to avoid issue with naming
class Clear::Expression::Node::PGArray(T) < Clear::Expression::Node
  @arr : Array(T)

  def initialize(@arr : Array(T))
  end

  def resolve : String
    safe_array = @arr.map{ |elm| Clear::Expression[elm] }
    {"array[", safe_array.join(", "), "]"}.join
  end
end
