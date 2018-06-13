module Clear::SQL::Query::Having
  macro included
    getter havings : Array(Clear::Expression::Node)
  end

  def having(&block)
    x = Clear::Expression.to_node(with Clear::Expression.new yield)
    @havings << Clear::Expression.to_node(with Clear::Expression.new yield)

    change!
  end

  def having(x : NamedTuple)
    sql = x.map do |k, v|
      case v
      when Array
        "#{k} IN (#{v.map { |x| Clear::Expression[x] }.join(", ")})"
      when SelectBuilder
        "#{k} IN (#{v.to_sql})"
      else
        "#{k} = #{Clear::Expression[v]}"
      end
    end.join(" AND ")

    @havings << Clear::Expression::Node::Variable.new(sql)

    change!
  end

  def having(str : String, parameters : Array(T)) forall T
    idx = -1

    clause = str.gsub(/\?/) do |_|
      begin
        Clear::Expression[parameters[idx += 1]]
      rescue e : IndexError
        raise QueryBuildingError.new(e.message)
      end
    end

    self.having(clause)
  end

  def having(str : String, parameters : NamedTuple)
    clause = str.gsub(/\:[a-zA-Z0-9_]+/) do |question_mark|
      begin
        sym = question_mark[1..-1]
        Clear::Expression[parameters[sym]]
      rescue e : KeyError
        raise QueryBuildingError.new(e.message)
      end
    end

    self.having(clause)
  end

  def having(str : String)
    @havings << Clear::Expression::Node::Variable.new(str)
    change!
  end

  def clear_havings
    @havings.clear

    change!
  end

  protected def print_havings
    if @havings.any?
      "HAVING " + @havings.map(&.resolve).join(" AND ")
    end
  end
end
