require "../factory"

module Clear::Model::HasFactory
  macro included # In Clear::Model
    macro included # In RealModel
      POLYMORPHISM_SETTINGS = {} of Nil => Nil

      class_getter? polymorphic : Bool = false

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

  # :nodoc:
  macro __default_factory__
    Clear::Model::Factory.add({{@type.stringify}}, ::Clear::Model::Factory::SimpleFactory({{@type}}).new)
  end

  # :nodoc:
  # Define a simple model factory which is litteraly just a
  # delegate to the constructor.
  macro __register_factory__
    {% unless POLYMORPHISM_SETTINGS[:has_factory] %}
      __default_factory__
    {% end %}
  end

  # Define a polymorphic factory, if the model is tagged as polymorphic
  macro polymorphic(through = "type")
    {% POLYMORPHISM_SETTINGS[:has_factory] = true %}

    column {{through.id}} : String

    before(:validate) do |model|
      model = model.as(self)
      model.{{through.id}} = model.class.name
    end

    # Subclasses are refined using a default scope
    # to filter by type.
    macro inherited
      class Collection < Clear::Model::CollectionBase(\{{@type}}); end

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

    Clear::Model::Factory.add("{{@type}}", Clear::Model::Factory::PolymorphicFactory({{@type}}).new({{through.id.stringify}}, "{{@type}}" ) )

    macro inherited
      Clear::Model::Factory.add("\{{@type}}", Clear::Model::Factory::SimpleFactory(\{{@type}}).new )
    end
  end
end
