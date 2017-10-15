module Clear::SQL::Query::OrderBy
  macro included
    getter order_bys : Array(String) = [] of String
  end

  def order_by(tuple : NamedTuple)
    tuple.each do |k, v|
      @order_bys << "#{k} #{v.to_s.upcase}"
    end
    self
  end

  def order_by(name, direction = :desc)
    @order_bys << "#{k} #{direction.to_s.upcase}"
  end

  protected def print_order_bys
    return unless @order_bys.any?
    "ORDER BY " + @order_bys.map(&.to_s).join(", ")
  end
end
