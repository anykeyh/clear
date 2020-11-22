# Encode for:
#
# `ORDER BY expression [ASC | DESC | USING operator] [NULLS FIRST | NULLS LAST];`
#
# Current implementation:
#
# [x] Multiple Order by clauses
# [x] ASC/DESC
# [x] NULLS FIRST / NULLS LAST
# [ ] NOT IMPLEMENTED: USING OPERATOR
module Clear::SQL::Query::OrderBy
  record Record, op : String, dir : Symbol, nulls : Symbol?

  macro included
    getter order_bys : Array(Clear::SQL::Query::OrderBy::Record) = [] of Clear::SQL::Query::OrderBy::Record
  end

  # Remove all order by clauses
  def clear_order_bys
    @order_bys.clear
    change!
  end

  # :nodoc:
  private def sanitize_direction(x)
    case x
    when :asc, :desc
      x
    else
      raise QueryBuildingError.new("Unknown direction for ORDER_BY: #{x.to_s.upcase}")
    end
  end

  # :nodoc:
  private def sanitize_nulls(x)
    case x
    when nil, :nulls_last, :nulls_first
      x
    else
      raise QueryBuildingError.new("Unknown ORDER_BY ... NULLS directive: #{x.to_s.upcase}")
    end
  end

  # Flip over all order bys by switching the ASC direction to DESC and the NULLS FIRST to NULLS LAST
  # ```
  #  query = Clear::SQL.select.from("users").order_by(id: :desc, name: :asc, company: {:asc, :nulls_last})
  #  query.reverse_order_by
  #  query.to_sql # SELECT * FROM users ORDER BY "id" ASC, "name" DESC, "company" DESC NULLS FIRST
  # ```
  #
  # return `self`
  def reverse_order_by
    @order_bys = @order_bys.map{ |rec|
      Record.new(rec.op,
        rec.dir == :desc ? :asc : :desc,
        rec.nulls.try{ |n| n == :nulls_last ? :nulls_first : :nulls_last }
      )
    }
    change!
  end

  # :nodoc:
  def order_by(x : Array(Record))
    @order_bys = x
    change!
  end

  # Add multiple ORDER BY clause using a tuple:
  #
  # ```
  #  query = Clear::SQL.select.from("users").order_by(id: :desc, name: { :asc, :nulls_last } )
  #  query.to_sql # > SELECT * FROM users ORDER BY "id" DESC, "name" ASC NULLS LAST
  # ```
  #
  def order_by(**tuple)
    order_by(tuple)
  end

  # :ditto:
  def order_by(__tuple : NamedTuple)
    __tuple.each do |k, v|
      case v
      when Symbol, String
        order_by(k, v, nil)
      when Tuple # order_by(column: {:asc, :nulls_first})
        order_by(k, v[0], v[1])
      else
        raise "order_by with namedtuple must be called with value of the tuple as Symbol, String or Tuple describing direction and nulls directive"
      end
    end

    self
  end

  # Add one ORDER BY clause
  # ```
  # query = Clear::SQL.select.from("users").order_by(:id, :desc, nulls_last)
  # query.to_sql #> SELECT * FROM users ORDER BY "id" DESC NULLS LAST
  # ```
  def order_by(expression : Symbol, direction : Symbol  = :asc, nulls : Symbol? = nil)
    @order_bys << Record.new(SQL.escape(expression.to_s), sanitize_direction(direction), sanitize_nulls(nulls))
    change!
  end

  # :ditto:
  def order_by(expression : String, direction : Symbol = :asc, nulls : Symbol? = nil)
    @order_bys << Record.new(expression, sanitize_direction(direction), sanitize_nulls(nulls))
    change!
  end

  # :nodoc:
  private def to_nulls_statement(symbol)
    case symbol
    when :nulls_first
      "NULLS FIRST"
    when :nulls_last
      "NULLS LAST"
    else
      nil
    end
  end

  # :nodoc:
  protected def print_order_bys
    return unless @order_bys.any?
    "ORDER BY " + @order_bys.map { |r| [ r.op, r.dir.to_s.upcase, to_nulls_statement(r.nulls) ].compact.join(" ") }.join(", ")
  end
end
