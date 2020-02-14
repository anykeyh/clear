module Clear::SQL::Query::GroupBy
  getter group_bys : Array(Symbolic)

  def clear_group_bys
    @group_bys.clear
    change!
  end

  def group_by(column : Symbolic)
    @group_bys << column
    change!
  end

  def group_by(*column_list)
    column_list.each { |col| @group_bys << column }
    change!
  end

  protected def print_group_bys
    return unless @group_bys.any?
    "GROUP BY " + @group_bys.map{ |x| x.is_a?(Symbol) ? SQL.escape(x) : x }.join(", ")
  end
end
