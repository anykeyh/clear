#
# Clear's Expression engine
# Provide natural way of writing down WHERE, JOIN and HAVING condition clause
#
class Clear::Expression
  DATABASE_DATE_TIME_FORMAT = "%Y-%m-%d %H:%M%S.%L"
  DATABASE_DATE_FORMAT      = "%Y-%m-%d"

  def self.[](*args) : String
    safe_literal(*args)
  end

  # Safe literal of a number is the number itself
  def self.safe_literal(x : Number) : String
    x.to_s
  end

  # Safe literal of a string. Replace the quote character to double-quote (postgres only)
  def self.safe_literal(x : String) : String
    "'" + x.gsub(/\'/, "''") + "'"
  end

  # Be able to use a Select Query as sub query
  def self.safe_literal(x : ::Clear::SQL::SelectQuery)
    "(#{x.to_sql})"
  end

  # Safe literal of a time is the time in the database format
  # @params date
  #   if date is passed, then only the date part of the Time is used:
  # ```
  # Clear::Expression[Time.now]             # < "2017-04-03 23:04:43.234"
  # Clear::Expression[Time.now, date: true] # < "2017-04-03"
  # ```
  def self.safe_literal(x : Time, date : Bool = false) : String
    "'" + x.to_s(date ? DATABASE_DATE_FORMAT : DATABASE_DATE_TIME_FORMAT) + "'"
  end

  def self.safe_literal(x : Bool) : String
    (x ? "TRUE" : "FALSE")
  end

  def self.safe_literal(x : Node) : String
    x.resolve
  end

  def self.safe_literal(x : _) : String
    self.safe_literal(x.to_s)
  end

  def self.to_node(node) : Node
    case node
    when Node
      node
    when Bool
      # Having precomputed boolean return is
      # interesting in debug mode and / or if the condition
      # can be computed before requesting. Therefore we trick the system to
      # allow this option
      #
      # Maybe it would be advisable to raise an error in this case,
      # because a developer mistake can create a boolean where he doesn't want to.
      node = Node::Variable.new(node ? "TRUE" : "FALSE")
    else
      raise ArgumentError.new("Node is incorrect, it must be Bool or ExpressionNode")
    end
  end

  # Return a node of the expression engine
  # This node can then be combined with others node
  # in case of chain request creation `where{...}.where{...}`
  # through the chaining engine
  def self.where(&block) : Node
    expression_engine = self.new

    node = to_node(with expression_engine yield)
  end

  # Not operator
  def not(x : Node)
    Node::Not.new(x)
  end

  # In case the name of the variable is a reserved word (e.g. not or ... raw :P)
  # or in case of a complex piece impossible to express with the expression engine
  # (mostly usage of functions)
  # you can use then raw
  #
  # where{ raw("COUNT(*)") > 5 }
  # TODO: raw should accept array splat as second parameters and the "?" keyword
  #
  def raw(x : String)
    Node::Variable.new(x)
  end

  def raw(x : Symbol)
    Node::Variable.new(x.to_s)
  end

  # Alias for raw since I deactivated the method_missing code
  def var(x)
    raw(x)
  end

  # macro method_missing(call)
  #   {% if call.args.size > 0 %}
  #     args = {{call.args}}.map{|x| Clear::Expression[x] }.join(", ")
  #     return Node::Variable.new("{{call.name.id}}( #{args} )")
  #   {% else %}
  #     return Node::Variable.new({{call.name.id.stringify}})
  #   {% end %}
  # end
end

require "./nodes/node"
require "./nodes/*"
