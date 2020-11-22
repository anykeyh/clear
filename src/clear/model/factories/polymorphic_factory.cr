require "./base"

module Clear::Model::Factory
  class PolymorphicFactory(T)
    include Base
    property type_field : String = ""
    property self_class : String = ""

    def initialize(@type_field, @self_class)
    end

    def build(h : Hash(String, ::Clear::SQL::Any),
              cache : Clear::Model::QueryCache? = nil,
              persisted : Bool = false,
              fetch_columns : Bool = false) : Clear::Model
      v = h[@type_field]

      case v
      when String
        if v == T.name
          {% if T.abstract? %}
            raise "Cannot instantiate #{@type_field} because it is abstract class"
          {% else %}
            T.new(v, h, cache, persisted, fetch_columns).as(Clear::Model)
          {% end %}
        else
          Clear::Model::Factory.build(v, h, cache, persisted, fetch_columns).as(Clear::Model)
        end
      when Nil
        raise Clear::ErrorMessages.polymorphic_nil(@type_field)
      else
        raise Clear::ErrorMessages.polymorphic_nil(@type_field)
      end
    end
  end
end
