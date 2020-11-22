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

  def contains?(expression : Clear::Expression::Node)
    Clear::Expression::Node::JSONB::ArrayContains.new(resolve, expression.resolve)
  end

  def contains?(expression)
    Clear::Expression::Node::JSONB::ArrayContains.new(resolve, Clear::Expression[expression])
  end
end

# Define a __value match? (@>)__ operation between a jsonb column and a json hash
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

# Define a __array contains? (?)__ operation between a jsonb column and a json hash
class Clear::Expression::Node::JSONB::ArrayContains < Clear::Expression::Node
  getter jsonb_field : String
  getter value : String

  def initialize(@jsonb_field, @value)
  end

  def resolve : String
    {@jsonb_field, @value}.join(" ? ")
  end
end
