module Clear::SQL::Query::Join
  macro included
    getter joins : Array(SQL::Join)
  end

  protected def join_impl(name : Symbolic, type, lateral, clear_expr)
    name = (name.is_a?(Symbol) ? Clear::SQL.escape(name.to_s) : name)

    joins << Clear::SQL::Join.new(name, clear_expr, lateral, type)
    change!
  end

  def join(name : Symbolic, type = :inner, lateral = false, &block)
    join_impl(name, type, lateral, Clear::Expression.ensure_node!(with Clear::Expression.new yield))
  end

  def join(name : Symbolic, type = :inner, lateral = false)
    join_impl(name, type, lateral, nil)
  end

  def cross_join(name : Symbolic, lateral = false)
    join(name, :cross, lateral = false)
  end

  {% for j in ["left", "right", "full_outer", "inner"] %}
    def {{j.id}}_join(name : Symbolic, lateral = false, &block)
      join_impl(name, :{{j.id}}, lateral, Clear::Expression.ensure_node!(with Clear::Expression.new yield))
    end
  {% end %}

  protected def print_joins
    joins.map(&.to_sql.as(String)).join(" ")
  end
end
