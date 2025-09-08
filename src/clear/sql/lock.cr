module Clear
  module SQL
    # Lock completetly a table.
    #
    # ```
    # Clear::SQL.lock("my_table") do
    # end
    # ```
    #
    # Optional parameter `mode` allow you to decide over the lock level
    # Modes are:
    # - ACCESS EXCLUSIVE (default)
    # - ACCESS SHARE
    # - ROW SHARE
    # - ROW EXCLUSIVE
    # - SHARE UPDATE EXCLUSIVE
    # - SHARE
    # - SHARE ROW EXCLUSIVE
    # - EXCLUSIVE
    #
    # See [Official PG documentation for more informations](https://www.postgresql.org/docs/12/explicit-locking.html)
    #
    def self.lock(table : String | Symbol, mode = "ACCESS EXCLUSIVE", connection = "default", &)
      Clear::SQL::ConnectionPool.with_connection(connection) do |cnx|
        transaction do
          execute("LOCK TABLE #{table} IN #{mode} MODE")
          return yield(cnx)
        end
      end
    end
  end
end
