module Clear::SQL::Query::GroupBy
  getter group_bys : Array(Symbolic)

  # Clear the group by clause
  def clear_group_bys
    @group_bys.clear
    change!
  end

  # Build a GROUP BY clause
  #
  # ```
  # query.select("department", "position").from(:users).group_by("department", "position")
  # # SELECT * FROM "users" GROUP BY department, position
  # ```
  def group_by(*column_list)
    column_list.each { |col| @group_bys << col }
    change!
  end

  protected def print_group_bys
    return unless @group_bys.any?
    "GROUP BY " + @group_bys.map{ |x| x.is_a?(Symbol) ? SQL.escape(x) : x }.join(", ")
  end
end
