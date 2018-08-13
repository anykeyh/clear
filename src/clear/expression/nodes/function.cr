require "./node"

#
#
class Clear::Expression::Node::Function < Clear::Expression::Node
  def initialize( @name : String, @args : Array(String) ); end

  def resolve
    {@name, "(", @args.join(", "), ")"}.join
  end
end
