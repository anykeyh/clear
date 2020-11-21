module Clear
  module SQL
    # Truncate a table or a model
    #
    # ```
    #   User.query.count # => 200
    #   Clear::SQL.truncate(User) # equivalent to Clear::SQL.truncate(User.table, connection_name: User.connection)
    #   User.query.count # => 0
    # ```
    #
    # SEE https://www.postgresql.org/docs/current/sql-truncate.html
    # for more information.
    #
    # - `restart_sequence` set to true will append `RESTART IDENTITY` to the query
    # - `cascade` set to true will append `CASCADE` to the query
    # - `truncate_inherited` set to false will append `ONLY` to the query
    # - `connection_name` will be: `Model.connection` or `default` unless optionally defined.
    def self.truncate(tablename : T.class | String | Symbol, restart_sequence = false, cascade = false, truncate_inherited = true, connection_name : String = "default" ) forall T

      case tablename
      when String
        # do nothing
      when Symbol
        tablename = Clear::SQL.escape(tablename.to_s)
      else
        # can check here the T.class
        connection_name = tablename.connection
        tablename = tablename.full_table_name
      end

      only = truncate_inherited ? "" : " ONLY "
      restart_sequence = restart_sequence ? " RESTART IDENTITY " : ""
      cascade = cascade ? " CASCADE " : ""

      execute(connection_name,
        {"TRUNCATE TABLE ", only, tablename, restart_sequence, cascade }.join
      )
    end
  end
end