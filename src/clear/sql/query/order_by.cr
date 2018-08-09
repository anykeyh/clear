module Clear::SQL::Query::OrderBy
  record Record, op : String, dir : Symbol

  macro included
    getter order_bys : Array(Record) = [] of Record
  end

  private def _order_by_to_symbol(str)
    case str.upcase
    when "DESC"
      :desc
    when "ASC"
      :asc
    else
      raise Clear::ErrorMessages.order_by_error_invalid_order(str)
    end
  end

  def clear_order_bys
    @order_bys.clear
    change!
  end

  def order_by( x : Array(Record) )
    @order_bys = x
    change!
  end

  def order_by(**tuple)
    tuple.each do |k, v|
      @order_bys << Record.new(k.to_s, _order_by_to_symbol(v.to_s))
    end
    change!
  end

  def order_by(tuple : NamedTuple)
    tuple.each do |k, v|
      @order_bys << Record.new(k.to_s, _order_by_to_symbol(v.to_s))
    end
    change!
  end

  def order_by(expression, direction="ASC")
    @order_bys << Record.new(expression, _order_by_to_symbol(direction))
    change!
  end

  protected def print_order_bys
    return unless @order_bys.any?
    "ORDER BY " + @order_bys.map{ |r| [r.op, r.dir.to_s.upcase].join(" ") }.join(", ")
  end
end
