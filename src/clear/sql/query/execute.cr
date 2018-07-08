require "db"

module Clear::SQL::Query::Execute
  # Execute an operation without asking for return
  # If an optional `connection_name` parameter is given, this will
  #   override the connection used.
  #
  # ```crystal
  # # Apply a method from an extension on multiple database
  #
  # %(default secondary).each do |cnx|
  #   Clear::SQL.select("pg_shards('xxx')").execute(cnx)
  # end
  # ```
  def execute(connection_name : String? = nil)
    connection_name ||= self.connection_name
    Clear::SQL.execute(connection_name, to_sql)
  end
end
