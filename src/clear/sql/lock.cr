module Clear
  module SQL
    # Tablewise locking
    def self.lock(table : String | Symbol, mode = "ACCESS EXCLUSIVE", connection = "default", &block)
      Clear::SQL::ConnectionPool.with_connection(connection) do |_|
        transaction do
          execute("LOCK TABLE #{table} IN #{mode} MODE")
          return yield
        end
      end
    end
  end
end
