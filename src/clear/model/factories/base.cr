module Clear::Model::Factory
  module Base
    abstract def build(h : Hash(String, ::Clear::SQL::Any),
                       cache : Clear::Model::QueryCache? = nil,
                       persisted : Bool = false,
                       fetch_columns : Bool = false) : Clear::Model
  end
end
