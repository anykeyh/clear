require "./jsonb"

class Clear::Expression::Node::JSONB::Field < Clear::Expression::Node
  include Clear::SQL::JSONB

  getter field : Node
  getter key : String

  def initialize(@field, @key)
  end

  def resolve
    jsonb_resolve(@field.resolve, jsonb_k2a(key))
  end

  def ==(value : Clear::Expression::Node)
    super(value) # << Keep same for node which are not literal value
  end

  def ==(value : _) # << For other type, literalize and use smart JSONB equality
    Clear::Expression::Node::JSONB::Equality.new(field.resolve, jsonb_k2h(key, value))
  end
end

# Define a __value contains?__ operation between a jsonb column and a json hash
class Clear::Expression::Node::JSONB::Equality < Clear::Expression::Node
  include Clear::SQL::JSONB

  getter jsonb_field : String
  getter value : JSONBHash

  def initialize(@jsonb_field, @value)
  end

  def resolve
    {@jsonb_field, Clear::Expression[@value.to_json]}.join(" @> ")
  end

  # In case of AND with another JSON equality test
  #   we merge both expression in only one !
  def &(other : self)
    if (other.jsonb_field == jsonb_field)
      Clear::Expression::Node::JSONB::Equality.new(jsonb_field,
        Clear::Util.hash_union(value, other.value)
      )
    else
      super(other)
    end
  end
end

class Clear::Expression::Node::Variable < Clear::Expression::Node
  def jsonb_key_exists?(key : String)
    Clear::Expression::Node::DoubleOperator.new(self, Clear::Expression::Node::Literal.new(key), "?")
  end

  def jsonb_any_key_exists?(keys : Array(String))
    Clear::Expression::Node::DoubleOperator.new(self,
      {"array[", keys.join(", "), "]"}.join
    ,"?|")
  end

  def jsonb_all_keys_exists?(keys : Array(String))
    Clear::Expression::Node::DoubleOperator.new(self,
      {"array[", keys.join(", "), "]"}.join
    ,"?&")
  end

  def jsonb(key : String)
    Clear::Expression::Node::JSONB::Field.new(self, key)
  end
end
