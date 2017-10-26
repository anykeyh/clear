module Clear::SQL::Query::Join
  macro included
    getter joins : Array(SQL::Join)
  end

  def join(name : Symbolic, type = :inner, &block)
    joins << Clear::SQL::Join.new(name, Clear::Expression.to_node(with Clear::Expression.new yield), type)
    self
  end

  def join(name : Symbolic, type = :inner)
    joins << Clear::SQL::Join.new(name, nil, type)
    self
  end

  def cross_join(name : Symbolic)
    join(name, type: :cross)
    self
  end

  {% for j in ["left", "right", "full_outer"] %}
    def {{j.id}}_join(name : Symbolic, &block)
      joins << Clear::SQL::Join.new(name, Clear::Expression.to_node(with Clear::Expression.new yield), :{{j.id}})
      self
    end
  {% end %}

  protected def print_joins
    joins.map(&.to_sql.as(String)).join(" ")
  end
end
