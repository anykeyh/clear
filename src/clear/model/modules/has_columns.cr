require "inflector/core_ext"
require "pg"

# This module declare all the methods and macro related to columns in `Clear::Model`
module Clear::Model::HasColumns
  macro included
    macro included
      COLUMNS = {} of Nil => Nil

      # Attributes, used if fetch_columns is true
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
  macro column(name, primary = false, converter = nil, column = nil, presence = true)
    {% _type = name.type %}
    {%
       unless converter
         if _type.is_a?(Path)
           converter = ("Clear::Model::Converter::" + _type.stringify + "Converter").id
         elsif _type.is_a?(Generic) # Union?
           converter = ("Clear::Model::Converter::" + _type.type_vars.map(&.stringify).sort.reject { |x| x == "::Nil" }.join("") + "Converter").id
         else
           converter = ("Clear::Model::Converter::" + _type.types.map(&.stringify).sort.reject { |x| x == "::Nil" }.join("") + "Converter").id
         end
       end %}

    {% COLUMNS[name.var] = {
         type:      _type,
         primary:   primary,
         converter: converter,
         column:    column || name.var,
         presence:  presence,
       } %}

  end

  # Used internally to gather the columns
  macro __generate_columns
    {% for name, settings in COLUMNS %}
      {% type = settings[:type] %}
      {% has_db_default = !settings[:presence] %}
      @{{name}}_column : Clear::Model::Column({{type}}) = Clear::Model::Column({{type}}).new("{{name}}",
        has_db_default: {{has_db_default}} )

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

    # Set the columns from hash
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

    def validate_field_presence
      {% for name, settings in COLUMNS %}
        unless persisted?
          if @{{name}}_column.failed_to_be_present?
            add_error({{name.stringify}}, "must be present")
          end
        end
      {% end %}
    end


    # Reset the `changed?` flag on all columns
    def clear_change_flags
      {% for name, settings in COLUMNS %}
        @{{name}}_column.clear_change_flag
      {% end %}
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

    def changed?
      {% for name, settings in COLUMNS %}
          return true if @{{name}}_column.changed?
      {% end %}

      return false
    end

    def persist!(pkey : ::Clear::SQL::Any)
      @persisted = true
      {% for name, settings in COLUMNS %}
        {% if settings[:primary] %}
          @{{name}}_column.reset({{settings[:converter]}}.to_column(pkey))
        {% end %}
      {% end %}
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
