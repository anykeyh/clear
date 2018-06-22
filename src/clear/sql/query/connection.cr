module Clear::SQL
  module Query::Connection
    getter connection_name : String = "default"

    def use_connection(@connection_name : String)
      self
    end
  end
end
