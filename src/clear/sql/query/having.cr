module Clear::SQL::Query::Having
  macro included
    getter havings : Array(Clear::Expression::Node)
  end

  # Build SQL `having` condition using a Clear::Expression::Node
  # ```crystal
  # query.having(Clear::Expression::Node::InArray.new("id", ['1', '2', '3', '4']))
  # # Note: in this example, InArray node use unsafe strings
  # ```
  # If useful for moving a having clause from a request to another one:
  # ```crystal
  # query1.having { a == b } # having a = b
  # ```
  # ```
  # query2.having(query1.havings[0]) # HAVING a = b
  # ```
  def having(node : Clear::Expression::Node)
    @havings << node
    change!
  end

  # Build SQL `or_having` condition using a Clear::Expression::Node
  # ```crystal
  # query.or_having(Clear::Expression::Node::InArray.new("id", ['1', '2', '3', '4']))
  # # Note: in this example, InArray node use unsafe strings
  # ```
  # If useful for moving a having clause from a request to another one:
  # ```crystal
  # query1.or_having { a == b } # having a = b
  # ```
  # ```
  # query2.or_having(query1.havings[0]) # having a = b
  # ```
  def or_having(node : Clear::Expression::Node)
    return having(node) if @havings.empty?

    # Optimisation: if we have a OR Array as root, we use it and append directly the element.
    if @havings.size == 1 &&
       (n = @havings.first) &&
       n.is_a?(Clear::Expression::Node::NodeArray) &&
       n.link == "OR"
      n.expression << node
    else
      # Concatenate the old clauses in a list of AND conditions
      if @havings.size == 1
        old_clause = @havings.first
      else
        old_clause = Clear::Expression::Node::NodeArray.new(@havings, "AND")
      end

      @havings.clear
      @havings << Clear::Expression::Node::NodeArray.new([old_clause, node], "OR")
    end

    change!
  end

  # Build SQL `having` condition using the Expression engine.
  # ```crystal
  # query.having { id == 1 }
  # ```
  def having(&block)
    having(Clear::Expression.ensure_node!(with Clear::Expression.new yield))
  end

  def having(**tuple)
    having(__conditions: tuple)
  end

  # Build SQL `having` condition using a NamedTuple.
  #   this will use:
  # - the `=` operator if compared with a literal
  # ```crystal
  # query.having({keyword: "hello"}) # having keyword = 'hello'
  # ```
  # - the `IN` operator if compared with an array:
  # ```crystal
  # query.having({x: [1, 2]}) # having x in (1, 2)
  # ```
  # - the `>=` and `<=` | `<` if compared with a range:
  # ```crystal
  # query.having({x: (1..4)})  # having x >= 1 AND x <= 4
  # query.having({x: (1...4)}) # having x >= 1 AND x < 4
  # ```
  # - You also can put another select query as argument:
  # ```crystal
  # query.having({x: another_select}) # having x IN (SELECT ... )
  # ```
  def having(__conditions : NamedTuple | Hash(String, Clear::SQL::Any))
    __conditions.each do |k, v|
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
          Clear::Expression::Node::DoubleOperator.new(k,
            Clear::Expression::Node::Literal.new(v),
            (v.nil? ? "IS" : "=")
          )
        end
    end

    change!
  end

  # Build SQL `having` interpolating `:keyword` with the NamedTuple passed in argument.
  # ```crystal
  # having("id = :id OR date >= :start", id: 1, start: 1.day.ago)
  # # having id = 1 AND date >= '201x-xx-xx ...'
  # ```
  def having(__template : String, **__tuple)
    having(Clear::Expression::Node::Raw.new(Clear::SQL.raw(__template, **__tuple)))
  end

  # Build SQL `having` condition using a template string and
  # interpolating `?` characters with parameters given in a tuple or array.
  # ```crystal
  # having("x = ? OR y = ?", 1, "l'eau") # having x = 1 OR y = 'l''eau'
  # ```
  # Raise error if there's not enough parameters to cover all the `?` placeholders
  def having(__template : String, *__args)
    having(Clear::Expression::Node::Raw.new(Clear::SQL.raw(__template, *__args)))
  end

  def or_having(__template : String, **__named_tuple)
    or_having(Clear::Expression::Node::Raw.new(Clear::Expression.raw("(#{__template})", **__named_tuple)))
  end

  def or_having(__template : String, *__args)
    or_having(Clear::Expression::Node::Raw.new(Clear::Expression.raw("(#{__template})", *__args)))
  end

  # Build SQL `having` condition using the Expression engine.
  # ```crystal
  # query.or_having { id == 1 }
  # ```
  def or_having(&block)
    or_having(Clear::Expression.ensure_node!(with Clear::Expression.new yield))
  end

  # Clear all the having clauses and return `self`
  def clear_havings
    @havings.clear

    change!
  end

  # :nodoc:
  protected def print_havings
    {"HAVING ", @havings.map(&.resolve).join(" AND ")}.join if @havings.any?
  end
end
