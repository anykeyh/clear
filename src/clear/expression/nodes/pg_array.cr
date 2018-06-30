require "./node"

# PG structure `array[args...]`
# Named PGArray instead of Array to avoid issue with naming
class Clear::Expression::Node::PGArray(T) < Clear::Expression::Node
  @arr : Array(T)

  def initialize(@arr : Array(T))
  end

  def resolve
    {"array[", Clear::Expression[@arr].join(", "), "]"}.join
  end
end
