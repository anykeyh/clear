module Clear::SQL::Query::Having
  macro included
    getter havings : Array(Clear::Expression::Node)
  end

  def having(&block)
    @havings << Clear::Expression.ensure_node!(with Clear::Expression.new yield)

    change!
  end

  def having(x : NamedTuple)
    x.each do |k, v|
      k = Clear::Expression::Node::Variable.new(k.to_s)

      @havings <<
        case v
        when Array
          Clear::Expression::Node::InArray.new(k, v.map { |it| Clear::Expression[it] })
        when SelectBuilder
          Clear::Expression::Node::InSelect.new(k, v)
        when Range
          Clear::Expression::Node::InRange.new(k,
            Clear::Expression[v.begin]..Clear::Expression[v.end],
            v.exclusive?)
        else
          v = Clear::Expression::Node::Literal.new(v)
          Clear::Expression::Node::DoubleOperator.new(k, v, "=")
        end
    end

    change!
  end

  def having(str : String, parameters : Array(T) | Tuple) forall T
    idx = -1

    clause = str.gsub("?") do |_|
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
    {"HAVING ", @havings.map(&.resolve).join(" AND ")}.join if @havings.any?
  end
end
