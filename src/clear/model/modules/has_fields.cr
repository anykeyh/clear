require "inflector/core_ext"
require "pg"

module Clear::Model::HasFields
  macro included
    FIELDS = {} of Nil => Nil
    getter attributes : Hash(String, ::Clear::SQL::Any) = {} of String => ::Clear::SQL::Any
  end

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
          if h.has_key?(:"{{settings[:field]}}")
            @{{name}}_field.reset({{settings[:converter]}}.to_field(h[:"{{settings[:field]}}"]))
          end
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
          out["{{settings[:field]}}"] = {{settings[:converter]}}.to_db(@{{name}}_field.value)
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
