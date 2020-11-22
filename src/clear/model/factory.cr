require "./factories/**"

module Clear::Model::Factory
  FACTORIES = {} of String => Clear::Model::Factory::Base # Used during compilation time

  macro add(type, factory)
    {% Clear::Model::Factory::FACTORIES[type] = factory %}
  end

  def self.build(type : String,
                 h : Hash,
                 cache : Clear::Model::QueryCache? = nil,
                 persisted = false,
                 fetch_columns = false) : Clear::Model
    factory = FACTORIES[type].as(Base)

    factory.build(h, cache, persisted, fetch_columns)
  end

  def self.build(type : T.class,
                 h : Hash,
                 cache : Clear::Model::QueryCache? = nil,
                 persisted = false,
                 fetch_columns = false) : T forall T
    self.build(T.name, h, cache, persisted, fetch_columns).as(T)
  end
end
