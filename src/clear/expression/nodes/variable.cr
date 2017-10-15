class Clear::Expression::Node::Variable < Clear::Expression::Node
  def initialize(@a : String); end

  def initialize(@name : String, @parent : Variable? = nil); end

  # macro method_missing(call)
  #   {% if call.args.size > 0 %}
  #     args = {{call.args}}.map{|x| Clear::Expression[x] }.join(", ")
  #     return Node::Variable.new("{{call.name.id}}( #{args} )", self)
  #   {% else %}
  #     return Node::Variable.new({{call.name.id.stringify}}, self)
  #   {% end %}
  # end

  def resolve
    parent = @parent
    if parent
      [parent.resolve, @name].join(".")
    else # nil
      @name
    end
  end
end
