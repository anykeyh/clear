require "../expression"

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
      Node::DoubleOperator.new(self, Literal.new(any), "{{sql_name.id}}")
    end
  end

  {% for op in [">", ">=", "<", "<=", "+", "-", "*", "/"] %}
    define_operator({{op}}, {{op}})
  {% end %}

  def =~(any : Node) : Node
    Node::DoubleOperator.new(self, any, "~")
  end

  def !~(any : Node) : Node
    Node::DoubleOperator.new(self, any, "!~")
  end

  def =~(regexp : Regex) : Node
    if regexp.options.ignore_case?
      Node::DoubleOperator.new(self, Literal.new(regexp.source), "~*")
    else
      Node::DoubleOperator.new(self, Literal.new(regexp.source), "~")
    end
  end

  def !~(regexp : Regex) : Node
    if regexp.options.ignore_case?
      Node::DoubleOperator.new(self, Literal.new(regexp.source), "!~*")
    else
      Node::DoubleOperator.new(self, Literal.new(regexp.source), "!~")
    end
  end

  define_operator("!=", "<>", null: "IS NOT")
  define_operator("==", "=", null: "IS")
  define_operator("like", "LIKE")
  define_operator("ilike", "ILIKE")
  define_operator("&", "AND")
  define_operator("|", "OR")

  def in?(range : Range(B, E)) forall B, E
    Node::InRange.new(self,
      Clear::Expression[range.begin]..Clear::Expression[range.end],
      range.exclusive?)
  end

  def in?(arr : Array(T)) forall T
    Node::InArray.new(self, arr.map { |x| Clear::Expression[x] })
  end

  def in?(tuple : Tuple(*T)) forall T
    in?(tuple.to_a)
  end

  def in?(request : ::Clear::SQL::SelectBuilder)
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
