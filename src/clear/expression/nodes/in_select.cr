require "./node"

#  A node managing the rendering of `value IN ( <SUBQUERY> )`
class Clear::Expression::Node::InSelect < Clear::Expression::Node
  def initialize(@target : Node, @select : Clear::SQL::SelectBuilder); end

  def resolve : String
    {@target.resolve, " IN (", @select.to_sql, ")"}.join
  end
end
