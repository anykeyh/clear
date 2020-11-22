require "./node"

# A node managing the rendering a range in Postgres.
#
# Example:
#
# ```crystal
# value.in?(1..5)
# ```
#
# will render:
#
# ```crystal
# value >= 1 AND value < 5
# ```
#
# Inclusion and exclusion of the last number of the range is featured
#
class Clear::Expression::Node::InRange < Clear::Expression::Node
  def initialize(@target : Node, @range : Range(String, String), @exclusive : Bool = false); end

  def resolve : String
    rt = @target.resolve
    final_op = @exclusive ? " < " : " <= "

    {"(", rt, " >= ", @range.begin, " AND ", rt, final_op, @range.end, ")"}.join
  end
end
