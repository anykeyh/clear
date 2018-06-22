require "db"

module Clear::SQL::Query::Execute
  def execute(connection_name : String = "default")
    Clear::SQL.execute(connection_name, to_sql)
  end
end
