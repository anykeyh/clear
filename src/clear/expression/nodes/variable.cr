require "./node"

###
# A variable AST node.
# It's what's created under the hood when you use a non-existent variable:
#
# ```
# where { users.id != nil }
#
# will produce this tree:
#
# # => double_operator('<>')
# #   # => variable('id', parent: 'users')
# #   # => null
#
# ```
class Clear::Expression::Node::Variable < Clear::Expression::Node
  def initialize(@name : String, @parent : Variable? = nil); end

  macro method_missing(call)
    {% if call.args.size > 0 %}
      args = Clear::Expression[{{call.args}}].join(", ")
      return Node::Variable.new("{{call.name.id}}(#{args})", self)
    {% else %}
      return Node::Variable.new({{call.name.id.stringify}}, self)
    {% end %}
  end

  def resolve : String
    parent = @parent
    if parent
      {parent.resolve, ".", Clear::SQL.escape(@name)}.join
    else # nil
      Clear::SQL.escape(@name)
    end
  end
end
