module Clear::SQL::Query::Where
  macro included
    getter wheres : Array(Clear::Expression::Node)
  end

  def where(node : Clear::Expression::Node)
    @wheres << node

    change!
  end

  def where(&block)
    where(Clear::Expression.to_node(with Clear::Expression.new yield))
  end

  def where(x : NamedTuple)
    sql = x.map do |k, v|
      case v
      when Array
        "#{k} IN (#{v.map { |x| Clear::Expression[x] }.join(", ")})"
      when SelectQuery
        "#{k} IN (#{v.to_sql})"
      else
        "#{k} = #{Clear::Expression[v]}"
      end
    end.join(" AND ")

    @wheres << Clear::Expression::Node::Variable.new(sql)

    change!
  end

  def where(str : String, parameters : Array(T)) forall T
    idx = -1

    clause = str.gsub(/\?/) do |_|
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
    if @wheres.any?
      "WHERE " + @wheres.map(&.resolve).join(" AND ")
    end
  end
end
