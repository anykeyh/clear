require "db"

module Clear::SQL::Query::Execute
  def execute
    Clear::SQL.execute(self.connection_name, to_sql)
  end
end
