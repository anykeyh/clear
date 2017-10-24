require "inflector/core_ext"
require "pg"

# This module declare all the methods and macro related to fields in `Clear::Model`
module Clear::Model::HasFields
  macro included
    macro included
      FIELDS = {} of Nil => Nil
      getter attributes : Hash(String, ::Clear::SQL::Any) = {} of String => ::Clear::SQL::Any
    end
  end

  # Access to direct SQL attributes given by the request used to build the model.
  # Access is read only and updating the model fields will not apply change to theses fields.
  def [](x) : ::Clear::SQL::Any
    attributes[x]
  end

  # Access to direct SQL attributes given by the request  used to build the model
  # or Nil if not found.
  # Access is read only and updating the model fields will not apply change to theses fields.
  def []?(x) : ::Clear::SQL::Any
    attributes[x]?
  end

  # Declare a field in the model.
  # Field are bound to a SQL column
  #
  # Simple example:
  # ```
  # class MyModel
  #   include Clear::Model
  #
  #   field some_id : Int32, primary: true
  #   field nullable_field : String?
  # end
  # ```
  # options:
  #
  # * `primary : Bool`: Let Clear ORM know which field is the primary key.
  # Currently compound primary key are not compatible with Clear ORM.
  #
  # * `converter : Class | Module`: Use this class to convert the data from the
  # SQL. This class must possess the class methods
  # `to_field(::Clear::SQL::Any) : T` and `to_db(T) : ::Clear::SQL::Any`
  # with `T` the type of the field.
  #
  # * `column : String`: If the name of the field in the model doesn't fit the name of the
  # column in the SQL, you can use the parameter `column` to tell Clear ORM about
  # which column is linked to the field.
  #
  macro field(name, primary = false, converter = nil, field = nil)
    {% type = name.type
       unless converter
         if type.is_a?(Path)
           converter = ("Clear::Model::Converter::" + type.stringify + "Converter").id
         else
           converter = ("Clear::Model::Converter::" + type.types.map(&.stringify).sort.reject { |x| x == "::Nil" }.join("") + "Converter").id
         end
       end %}

    {% FIELDS[name.var] = {
         type:      type,
         primary:   primary,
         converter: converter,
         field:     field || name.var,
       } %}

  end

  # Used internally to gather the fields
  macro __generate_fields
    {% for name, settings in FIELDS %}
      {% type = settings[:type] %}
      @{{name}}_field : Clear::Model::Field({{type}}) = Clear::Model::Field({{type}}).new("{{name}}")

      def {{name}}_field : Clear::Model::Field({{type}})
        @{{name}}_field
      end

      def {{name}} : {{type}}
        @{{name}}_field.value
      end

      def {{name}}=(x : {{type}})
        @{{name}}_field.value = x
      end

      {% if settings[:primary] %}
        def self.pkey
          "{{name}}"
        end

        def pkey
          @{{name}}_field.value
        end
      {% end %}
    {% end %}

    def set( t : NamedTuple )
      set(t.to_h)
    end

    def set( h : Hash(Symbol, ::Clear::SQL::Any) )
      {% for name, settings in FIELDS %}
        v = h[:"{{settings[:field]}}"].fetch(Field::UNKNOWN)
        @{{name}}_field.reset({{settings[:converter]}}.to_field(v)) if v != Field::UNKNOWN
      {% end %}
    end

    # Generate the hash for update request (like during save)
    def update_h : Hash(String, ::Clear::SQL::Any)
      out = {} of String => ::Clear::SQL::Any

      {% for name, settings in FIELDS %}
        if @{{name}}_field.defined? &&
           @{{name}}_field.changed?
          out["{{settings[:field]}}"] = {{settings[:converter]}}.to_db(@{{name}}_field.value)
        end
      {% end %}

      out
    end

    def to_h : Hash(String, ::Clear::SQL::Any)
      out = {} of String => ::Clear::SQL::Any

      {% for name, settings in FIELDS %}
        if @{{name}}_field.defined?
          out["{{settings[:field]}}"] = {{settings[:converter]}}.to_db(@{{name}}_field.value(nil))
        end
      {% end %}

      out
    end

    def set( h : Hash(String, ::Clear::SQL::Any) )
      {% for name, settings in FIELDS %}
        if h.has_key?("{{settings[:field]}}")
          @{{name}}_field.reset({{settings[:converter]}}.to_field(h["{{settings[:field]}}"]))
        end
      {% end %}
    end

  end
end
