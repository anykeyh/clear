module Clear::SQL::Query::Join
  macro included
    getter joins : Array(SQL::Join)
  end

  protected def join_impl(name : Symbolic, type, clear_expr)
    joins << Clear::SQL::Join.new(name, clear_expr, type)
    change!
  end

  def join(name : Symbolic, type = :inner, &block)
    join_impl(name, type, Clear::Expression.ensure_node!(with Clear::Expression.new yield))
  end

  def join(name : Symbolic, type = :inner)
    join_impl(name, type, nil)
  end

  def cross_join(name : Symbolic)
    join(name, :cross)
  end

  {% for j in ["left", "right", "full_outer"] %}
    def {{j.id}}_join(name : Symbolic, &block)
      join_impl(name, :{{j.id}}, Clear::Expression.ensure_node!(with Clear::Expression.new yield))
    end
  {% end %}

  protected def print_joins
    joins.map(&.to_sql.as(String)).join(" ")
  end
end
