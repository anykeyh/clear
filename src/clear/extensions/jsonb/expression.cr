require "./jsonb"

class Clear::Expression::Node::JSONB::Field < Clear::Expression::Node
  include Clear::SQL::JSONB

  getter field : Node
  getter key : String
  getter cast : String?

  def initialize(@field, @key, @cast = nil)
  end

  def resolve : String
    jsonb_resolve(@field.resolve, jsonb_k2a(key), @cast)
  end

  def cast(@cast)
    self
  end

  def ==(value : Clear::Expression::Node)
    super(value) # << Keep same for node which are not literal value
  end

  def ==(value : _) # << For other type, literalize and use smart JSONB equality
    if @cast
      super(value)
    else
      Clear::Expression::Node::JSONB::Equality.new(field.resolve, jsonb_k2h(key, value))
    end
  end
end

# Define a __value contains?__ operation between a jsonb column and a json hash
class Clear::Expression::Node::JSONB::Equality < Clear::Expression::Node
  include Clear::SQL::JSONB

  getter jsonb_field : String
  getter value : JSONBHash

  def initialize(@jsonb_field, @value)
  end

  def resolve : String
    {@jsonb_field, Clear::Expression[@value.to_json]}.join(" @> ")
  end
end
