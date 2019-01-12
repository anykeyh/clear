require "db"

module Clear::SQL::Query::Execute
  #
  # Execute an SQL statement which does not return anything.
  #
  # If an optional `connection_name` parameter is given, this will
  #   override the connection used by the query.
  #
  # ```crystal
  # %(default secondary).each do |cnx|
  #   Clear::SQL.select("pg_shards('xxx')").execute(cnx)
  # end
  # ```
  def execute(connection_name : String? = nil)
    Clear::SQL.execute(connection_name || self.connection_name, to_sql)
  end
end
