module Clear::SQL::Query::GroupBy
  getter group_bys : Array(SQL::Column)

  protected def print_group_bys
    return unless @group_bys.any?
    "GROUP BY " + @group_bys.map(&.to_sql.as(String)).join(", ")
  end
end
