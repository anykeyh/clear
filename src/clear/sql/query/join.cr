module Clear::SQL::Query::Join
  macro included
    getter joins : Array(SQL::Join)
  end

  # :nodoc:
  protected def join_impl(name : Selectable, type, lateral, clear_expr)
    name = (name.is_a?(Symbol) ? Clear::SQL.escape(name.to_s) : name)

    joins << Clear::SQL::Join.new(name, clear_expr, lateral, type)
    change!
  end

  def join(name : Selectable, type = :inner, lateral = false, &block)
    join_impl(name, type, lateral, Clear::Expression.ensure_node!(with Clear::Expression.new yield))
  end

  def join(name : Selectable, type = :inner, condition : String = "true", lateral = false)
    join_impl(name, type, lateral, Clear::Expression::Node::Raw.new("(" + condition + ")"))
  end

  def join(name : Selectable, type = :inner, lateral = false)
    join_impl(name, type, lateral, nil)
  end

  def cross_join(name : Selectable, lateral = false)
    join(name, :cross, lateral)
  end

  {% for j in ["left", "right", "full_outer", "inner"] %}
    # Add a {{"#{j.id}".upcase}} JOIN directive to the query
    def {{j.id}}_join(name : Selectable, lateral = false, &block)
      join_impl(name, :{{j.id}}, lateral, Clear::Expression.ensure_node!(with Clear::Expression.new yield))
    end

    # Add a {{"#{j.id}".upcase}} JOIN directive to the query
    def {{j.id}}_join(name : Selectable, condition : String = "true", lateral = false)
      join_impl(name, :{{j.id}}, lateral, Clear::Expression::Node::Raw.new( "(" + condition + ")"))
    end
  {% end %}

  protected def print_joins
    joins.join(" ", &.to_sql.as(String))
  end
end
