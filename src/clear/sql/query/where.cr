module Clear::SQL::Query::Where
  macro included
    getter wheres : Array(Clear::Expression::Node)
  end

  def where(node : Clear::Expression::Node)
    @wheres << node

    change!
  end

  def where(&block)
    where(Clear::Expression.ensure_node!(with Clear::Expression.new yield))
  end

  def where(x : NamedTuple)
    x.each do |k, v|
      k = Clear::Expression::Node::Variable.new(k.to_s)

      @wheres <<
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

  def where(str : String, parameters : Array(T) | Tuple) forall T
    idx = -1

    clause = str.gsub("?") do |_|
      begin
        Clear::Expression[parameters[idx += 1]]
      rescue e : IndexError
        raise QueryBuildingError.new(e.message)
      end
    end

    self.where(clause)
  end

  def where(str : String, parameters : NamedTuple)
    clause = str.gsub(/\:[a-zA-Z0-9_]+/) do |question_mark|
      begin
        sym = question_mark[1..-1]
        Clear::Expression[parameters[sym]]
      rescue e : KeyError
        raise QueryBuildingError.new(e.message)
      end
    end

    self.where(clause)
  end

  def where(str : String)
    @wheres << Clear::Expression::Node::Variable.new(str)
    change!
  end

  def clear_wheres
    @wheres.clear

    change!
  end

  protected def print_wheres
    {"WHERE ", @wheres.map(&.resolve).join(" AND ")}.join if @wheres.any?
  end
end
