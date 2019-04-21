module Clear
  module SQL
    # Tablewise locking
    def self.lock(table : String | Symbol, mode = "ACCESS EXCLUSIVE", connection = "default", &block)
      Clear::SQL::ConnectionPool.with_connection(connection) do |cnx|
        transaction do
          execute("LOCK TABLE #{table.to_s} IN #{mode} MODE")
          return yield
        end
      end
    end
  end
end