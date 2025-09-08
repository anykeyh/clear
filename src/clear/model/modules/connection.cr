module Clear::Model::Connection
  macro included # When included into Model
    macro included # When included into final Model
      # Define on which connection the model is living. Useful in case of models living in different databases.
      #
      # Is set to "default" by default.
      #
      # See `Clear::SQL#init(URI, *opts)` for more information about multi-connections.
      #
      # Example:
      # ```
      # Clear::SQL.init("postgres://postgres@localhost/database_1", connection_pool_size: 5)
      # Clear::SQL.init("secondary", "postgres://postgres@localhost/database_2", connection_pool_size: 5)
      #
      # class ModelA
      #   include Clear::Model
      #
      #   # Performs all the queries on `database_1`
      #   # self.connection = "default"
      #   column id : Int32, primary: true, presence: false
      #   column title : String
      # end
      #
      # class ModelB
      #   include Clear::Model
      #
      #   # Performs all the queries on `database_2`
      #   self.connection = "secondary"
      #
      #   column id : Int32, primary: true, presence: false
      # end
      # ```
      class_property connection : String = "default"
    end
  end
end
