module Clear::SQL
  module Query::Connection
    # Connection used by the query.
    # Change it using `use_connection` method
    getter connection_name : String = "default"

    # Change the connection used by the query on execution
    def use_connection(@connection_name : String)
      self
    end
  end
end
