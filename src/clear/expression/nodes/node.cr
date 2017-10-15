abstract class Clear::Expression::Node
  macro define_operator(op_name, sql_name, null = false)
    def {{op_name.id}}(any : Node) : Node
      Node::DoubleOperator.new(self, any, "{{sql_name.id}}")
    end

    {% if null %}
      def {{op_name.id}}(some_nil : Nil) : Node
        Node::DoubleOperator.new(self, Null.new, {{null}} )
      end
    {% end %}

    def {{op_name.id}}(any : T) : Node forall T
      Node::DoubleOperator.new(self, Literal(T).new(any), "{{sql_name.id}}")
    end
  end

  {% for op in [">", ">=", "<", "<=", "+", "-", "*", "/"] %}
    define_operator({{op}}, {{op}})
  {% end %}

  define_operator("!=", "<>", null: "IS NOT")
  define_operator("==", "=", null: "IS")
  define_operator("=~", "LIKE")
  define_operator("like", "LIKE")
  define_operator("ilike", "ILIKE")
  define_operator("&", "AND")
  define_operator("|", "OR")

  def in?(arr : Array(T)) forall T
    Node::InArray(T).new(self, arr.map { |x| Literal(T).new(x) })
  end

  def in?(request : Clear::SQL::SelectQuery)
    Node::InSelect.new(self, request)
  end

  def between(a, b)
    Node::Between.new(self, a, b)
  end

  def -
    Node::Minus.new(self)
  end

  def ~
    Node::Not.new(self)
  end

  abstract def resolve : String
end
