require "./node"

# A node managing the rendering of functions in Postgres.
class Clear::Expression::Node::Function < Clear::Expression::Node
  def initialize(@name : String, @args : Array(String)); end

  def resolve : String
    {@name, "(", @args.join(", "), ")"}.join
  end
end
