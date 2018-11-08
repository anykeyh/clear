require "pg"
require "json"

module Clear::Model::Converter
  abstract class Base
  end

  CONVERTERS = {} of String => Base.class

  macro add_converter(name, klazz)
    {% CONVERTERS[name] = klazz %}
  end

  macro to_column(name, value)
    {% if !name.is_a?(StringLiteral) %}
      {% name = "#{name}" %}
    {% end %}

    {% if CONVERTERS[name] == nil %}
      {% raise "Unknown converter: #{name}" %}
    {% end %}

    {{ CONVERTERS[name] }}.to_column({{value}})
  end

  macro to_db(name, value)
    {% if !name.is_a?(StringLiteral) %}
      {% name = "#{name.resolve}" %}
    {% end %}

    {% if CONVERTERS[name] == nil %}
      {% raise "Unknown converter: #{name}" %}
    {% end %}

    {{ CONVERTERS[name] }}.to_db({{value}})
  end
end
