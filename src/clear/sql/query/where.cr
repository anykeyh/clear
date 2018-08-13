# Feature WHERE clause building.
# each call to where method stack where clause.
# Theses clauses are then combined together using the `AND` operator.
# Therefore, `query.where("a").where("b")` will return `a AND b`
#
module Clear::SQL::Query::Where
  macro included
    # Return the list of where clause; each where clause are transformed into
    # Clear::Expression::Node
    getter wheres : Array(Clear::Expression::Node)
  end

  # Build SQL `where` condition using a Clear::Expression::Node
  # ```crystal
  # query.where(Clear::Expression::Node::InArray.new("id", ['1', '2', '3', '4']))
  # # Note: in this example, InArray node use unsafe strings
  # ```
  # If useful for moving a where clause from a request to another one:
  # ```crystal
  # query1.where { a == b } # WHERE a = b
  # ```
  # ```
  # query2.where(query1.wheres[0]) # WHERE a = b
  # ```
  def where(node : Clear::Expression::Node)
    @wheres << node

    change!
  end

  # Build SQL `where` condition using the Expression engine.
  # ```crystal
  # query.where { id == 1 }
  # ```
  def where(&block)
    where(Clear::Expression.ensure_node!(with Clear::Expression.new yield))
  end

  # Build SQL `where` condition using a NamedTuple.
  #   this will use:
  # - the `=` operator if compared with a literal
  # ```crystal
  # query.where({keyword: "hello"}) # WHERE keyword = 'hello'
  # ```
  # - the `IN` operator if compared with an array:
  # ```crystal
  # query.where({x: [1, 2]}) # WHERE x in (1,2)
  # ```
  # - the `>=` and `<=` | `<` if compared with a range:
  # ```crystal
  # query.where({x: (1..4)})  # WHERE x >= 1 AND x <= 4
  # query.where({x: (1...4)}) # WHERE x >= 1 AND x < 4
  # ```
  # - You also can put another select query as argument:
  # ```crystal
  # query.where({x: another_select}) # WHERE x IN (SELECT ... )
  # ```
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

  # Build SQL `where` condition using a template string and
  # interpolating `?` characters with parameters given in a tuple or array.
  # ```crystal
  # where("x = ? OR y = ?", {1, "l'eau"}) # WHERE x = 1 OR y = 'l''eau'
  # ```
  # Raise error if there's not enough parameters to cover all the `?` placeholders
  def where(str : String, parameters : Array(T) | Tuple) forall T
    idx = -1

    clause = str.gsub("?") do |_|
      begin
        Clear::Expression[parameters[idx += 1]]
      rescue e : IndexError
        raise Clear::ErrorMessages.query_building_error(e.message)
      end
    end

    self.where(clause)
  end

  # Build SQL `where` interpolating `:keyword` with the NamedTuple passed in argument.
  # ```crystal
  # where("id = :id OR date >= :start", {id: 1, start: 1.day.ago})
  # # WHERE id = 1 AND date >= '201x-xx-xx ...'
  # ```
  def where(str : String, parameters : NamedTuple)
    clause = str.gsub(/\:[a-zA-Z0-9_]+/) do |question_mark|
      begin
        sym = question_mark[1..-1]
        Clear::Expression[parameters[sym]]
      rescue e : KeyError
        raise Clear::ErrorMessages.query_building_error(e.message)
      end
    end

    self.where(clause)
  end

  # Build custom SQL `where`
  #   beware of SQL injections!
  # ```crystal
  # where("ADD_SOME_DANGEROUS_SQL_HERE") # WHERE ADD_SOME_DANGEROUS_SQL_HERE
  # ```
  def where(str : String)
    @wheres << Clear::Expression::Node::Raw.new(str)
    change!
  end

  # Clear all the where clauses and return `self`
  def clear_wheres
    @wheres.clear

    change!
  end

  # :nodoc:
  protected def print_wheres
    {"WHERE ", @wheres.map(&.resolve).join(" AND ")}.join if @wheres.any?
  end
end
