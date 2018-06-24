# List of helpers for JSONB
#
require "json"

module Clear::SQL::JSONB
  extend self

  alias JSONBKey = JSONBHash | String | Int32 | Int64
  alias JSONBHash = Hash(String, JSONBKey)

  # Transform a key to a hash
  def jsonb_k2h(key : String) : JSONBHash
    jsonb_arr2h(jsonb_k2a(key))
  end

  # jsonb `?|` operator
  # Do any of these array strings exist as top-level keys?
  #
  def jsonb_any_exists?(field, keys : Array(String))
    [field, "array[" + keys.map { |x| Clear::SQL.sanitize(x) }.join(",") + "]"].join(" ?| ")
  end

  # Does the string exist as a top-level key within the JSON value?
  def jsonb_exists?(field, value)
    [field, Clear::SQL.sanitize(value)].join(" ? ")
  end

  # jsonb `?&` operator
  # Do all of these array strings exist as top-level keys?
  def jsonb_all_exists?(field, keys : Array(String))
    [field, "array[" + keys.map { |x| Clear::SQL.sanitize(x) }.join(",") + "]"].join(" ?& ")
  end

  # :nodoc:
  def jsonb_arr2h(key : Array(String), value : JSONBKey, idx = 0) : JSONBHash
    h = Hash(String, JSONBKey).new

    if idx == key.size - 1
      h[key[idx]] = value
    else
      h[key[idx]] = jsonb_arr2h(key, value, idx + 1)
    end

    return h
  end

  # :nodoc:
  def jsonb_k2a(key : String) : Array(String)
    arr = [] of String

    ignore_next = false
    buff = "" # Todo: Use stringbuffer

    key.chars.each do |c|
      if ignore_next
        ignore_next = false
        buff += c
        next
      end

      case c
      when '\\'
        ignore_next = true
      when '.'
        arr << buff
        buff = ""
      else
        buff += c
      end
    end

    unless buff.empty?
      arr << buff
    end

    return arr
  end

  # Test equality using the `@>` operator
  #
  # ```crystal
  # jsonb_eq("data.sub.key", "value")
  # ```
  #
  # => `data @> '{"sub": {key: "value"}}' `
  def jsonb_eq(key, value)
    arr = jsonb_k2a(key)

    if arr.size == 1
      return [arr[0], Clear::Expression[value]].join("=")
    else
      return [arr[0], Clear::Expression[jsonb_arr2h(arr[1..-1], value).to_json]].join(" @> ")
    end
  end

  # Return text selector for the field/key :
  #
  # ```crystal
  # jsonb_text("data", "sub.key").like("user%")
  # # => "data->'sub'->'key'::text LIKE 'user%'"
  # ```
  #
  def jsonb_text(key)
    arr = jsonb_k2a(key)
    arr.map_with_index do |v, idx|
      idx == 0 ? v : Clear::Expression[v]
    end.join("->") + "::text"
  end
end

# Add json helpers methods into expression engine.
class Clear::Expression
  # Delegate all the methods of Clear::SQL::JSONB methods
  {% for method in Clear::SQL::JSONB.methods %}
    def {{method.name}}({{method.args.join(", ").id}})
      {% arg_names = [] of String %}
      {% for arg in method.args %}
        {% arg_names << arg.name %}
      {% end %}
      raw(Clear::SQL::JSONB.{{method.name}}({{arg_names.join(", ").id}}))
    end
  {% end %}
end
