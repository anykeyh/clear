module Clear::SQL
  module Query::Connection
    getter connection_name : Symbolic = "default"

    def use_connection(@connection_name : Symbolic)
      self
    end
  end
end
