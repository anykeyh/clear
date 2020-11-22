require "./base"

module Clear::Model::Factory
  class SimpleFactory(T)
    include Base

    def build(h : Hash(String, ::Clear::SQL::Any),
              cache : Clear::Model::QueryCache? = nil,
              persisted : Bool = false,
              fetch_columns : Bool = false) : Clear::Model
      T.new(h, cache, persisted, fetch_columns).as(Clear::Model)
    end
  end
end
