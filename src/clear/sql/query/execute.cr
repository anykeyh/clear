require "db"

module Clear::SQL::Query::Execute
  def execute
    Clear::SQL.execute(to_sql)
  end
end
