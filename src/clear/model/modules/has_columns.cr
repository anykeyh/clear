require "inflector/core_ext"
require "pg"

# This module declare all the methods and macro related to columns in `Clear::Model`
module Clear::Model::HasColumns
  macro included
    macro included
      COLUMNS = {} of Nil => Nil
      getter attributes : Hash(String, ::Clear::SQL::Any) = {} of String => ::Clear::SQL::Any
    end
  end

  # Access to direct SQL attributes given by the request used to build the model.
  # Access is read only and updating the model columns will not apply change to theses columns.
  def [](x) : ::Clear::SQL::Any
    attributes[x]
  end

  # Access to direct SQL attributes given by the request  used to build the model
  # or Nil if not found.
  # Access is read only and updating the model columns will not apply change to theses columns.
  def []?(x) : ::Clear::SQL::Any
    attributes[x]?
  end

  # Bind a column to the model.
  #
  # Simple example:
  # ```
  # class MyModel
  #   include Clear::Model
  #
  #   column some_id : Int32, primary: true
  #   column nullable_column : String?
  # end
  # ```
  # options:
  #
  # * `primary : Bool`: Let Clear ORM know which column is the primary key.
  # Currently compound primary key are not compatible with Clear ORM.
  #
  # * `converter : Class | Module`: Use this class to convert the data from the
  # SQL. This class must possess the class methods
  # `to_column(::Clear::SQL::Any) : T` and `to_db(T) : ::Clear::SQL::Any`
  # with `T` the type of the column.
  #
  # * `column : String`: If the name of the column in the model doesn't fit the name of the
  # column in the SQL, you can use the parameter `column` to tell Clear ORM about
  # which column is linked to the column.
  #
  macro column(name, primary = false, converter = nil, column = nil)
    {% type = name.type
       unless converter
         if type.is_a?(Path)
           converter = ("Clear::Model::Converter::" + type.stringify + "Converter").id
         elsif type.is_a?(Generic) # Union?
           converter = ("Clear::Model::Converter::" + type.type_vars.map(&.stringify).sort.reject { |x| x == "::Nil" }.join("") + "Converter").id
         else
           converter = ("Clear::Model::Converter::" + type.types.map(&.stringify).sort.reject { |x| x == "::Nil" }.join("") + "Converter").id
         end
       end %}

    {% COLUMNS[name.var] = {
         type:      type,
         primary:   primary,
         converter: converter,
         column:    column || name.var,
       } %}

  end

  # Used internally to gather the columns
  macro __generate_columns
    {% for name, settings in COLUMNS %}
      {% type = settings[:type] %}
      @{{name}}_column : Clear::Model::Column({{type}}) = Clear::Model::Column({{type}}).new("{{name}}")

      def {{name}}_column : Clear::Model::Column({{type}})
        @{{name}}_column
      end

      def {{name}} : {{type}}
        @{{name}}_column.value
      end

      def {{name}}=(x : {{type}})
        @{{name}}_column.value = x
      end

      {% if settings[:primary] %}
        def self.pkey
          "{{name}}"
        end

        def pkey
          @{{name}}_column.value
        end
      {% end %}
    {% end %}

    def set( t : NamedTuple )
      set(t.to_h)
    end

    def set( h : Hash(Symbol, ::Clear::SQL::Any) )
      {% for name, settings in COLUMNS %}
        v = h.fetch(:"{{settings[:column]}}"){ Column::UNKNOWN }
        @{{name}}_column.reset({{settings[:converter]}}.to_column(v)) unless v.is_a?(Column::UnknownClass)
      {% end %}
    end

    # Generate the hash for update request (like during save)
    def update_h : Hash(String, ::Clear::SQL::Any)
      out = {} of String => ::Clear::SQL::Any

      {% for name, settings in COLUMNS %}
        if @{{name}}_column.defined? &&
           @{{name}}_column.changed?
          out["{{settings[:column]}}"] = {{settings[:converter]}}.to_db(@{{name}}_column.value)
        end
      {% end %}

      out
    end

    def to_h : Hash(String, ::Clear::SQL::Any)
      out = {} of String => ::Clear::SQL::Any

      {% for name, settings in COLUMNS %}
        if @{{name}}_column.defined?
          out["{{settings[:column]}}"] = {{settings[:converter]}}.to_db(@{{name}}_column.value(nil))
        end
      {% end %}

      out
    end

    def set( h : Hash(String, ::Clear::SQL::Any) )
      {% for name, settings in COLUMNS %}
        if h.has_key?("{{settings[:column]}}")
          @{{name}}_column.reset({{settings[:converter]}}.to_column(h["{{settings[:column]}}"]))
        end
      {% end %}
    end

  end
end
