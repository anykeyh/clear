module Clear::Model::IsPolymorphic
  macro included
    macro included
      SETTINGS = {} of Nil => Nil
    end
  end

  abstract class Factory
    abstract def build(h : Hash(String, ::Clear::SQL::Any),
                       cache : Clear::Model::QueryCache? = nil,
                       persisted = false,
                       fetch_columns = false) : Clear::Model
  end

  macro included
    macro included
      class_getter? polymorphic : Bool = false
      class_getter! factory : Factory

      # Add linking between classes for the EventManager triggers
      macro inherited
        \\{% for ancestor in @type.ancestors %}
          \\{% if ancestor < Clear::Model %}
            Clear::Model::EventManager.add_inheritance(\\{{ancestor}}, \\{{@type}})
          \\{% end %}
        \\{% end %}
      end
    end
  end

  # Define a simple model factory which is litteraly just a
  # delegate to the constructor.
  macro __init_default_factory
    {% unless SETTINGS[:has_factory] %}
      class Factory < ::Clear::Model::IsPolymorphic::Factory
        def build(h : Hash(String, ::Clear::SQL::Any ),
                  cache : Clear::Model::QueryCache? = nil,
                  persisted = false,
                  fetch_columns = false)
          {{@type}}.new(h, cache, persisted, fetch_columns)
        end
      end

      @@factory = Factory.new
    {% end %}
  end

  # Define a polymorphic factory, if the model is tagged as polymorphic
  macro polymorphic(*class_list, through = "type")
    {% SETTINGS[:has_factory] = true %}
    {% if class_list.size == 0 %}
      {% raise "Please setup subclass list for polymorphism." %}
    {% end %}

    column {{through.id}} : String

    before(:validate) do |model|
      model = model.as(self)
      model.{{through.id}} = model.class.name
    end

    # Subclasses are refined using a default scope
    # to filter by type.
    macro inherited
      def self.query
        Collection.new.from(table).where{ {{through.id}} == self.name }
      end
    end

    # Base class can be refined too, only if the baseclass is not abstract.
    {% unless @type.abstract? %}
      def self.query
        Collection.new.from(table).where{ {{through.id}} == self.name }
      end
    {% end %}

    def self.polymorphic?
      true
    end

    class Factory < ::Clear::Model::Factory
      def initialize(@through : String)
      end

      def build(h : Hash(String, ::Clear::SQL::Any ),
                cache : Clear::Model::QueryCache? = nil,
                persisted = false,
                fetch_columns = false)
        case h[@through]?
        {% for c in class_list %}
          when {{c.id}}.name
            {{c.id}}.new(h, cache, persisted, fetch_columns)
        {% end %}
        when nil
          raise Clear::ErrorMessages.polymorphic_nil(@through)
        else
          raise Clear::ErrorMessages.polymorphic_unknown_class(h[@through])
        end
      end
    end

    @@factory = Factory.new({{through}})
  end
end
