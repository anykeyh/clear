module Clear::SQL::Query::GroupBy
  getter group_bys : Array(String)

  def clear_group_bys
    @group_bys.clear
    change!
  end

  def group_by(column)
    @group_bys << column
    change!
  end

  protected def print_group_bys
    return unless @group_bys.any?
    "GROUP BY " + @group_bys.join(", ")
  end
end
