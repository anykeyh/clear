class Clear::Expression::Node::Literal(T) < Clear::Expression::Node
  def initialize(@lit : T)
  end

  def resolve
    Clear::Expression[@lit]
  end
end
