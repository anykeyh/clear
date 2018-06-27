require "./node"

class Clear::Expression::Node::InRange < Clear::Expression::Node
  def initialize(@target : Node, @range : Range(String, String), @exclusive = false); end

  def resolve
    rt = @target.resolve
    final_op = @exclusive ? " < " : " <= "

    {"(", rt, " >= ", @range.begin, " AND ", rt, final_op, @range.end, ")"}.join
  end
end
