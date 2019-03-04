#
# ## JSONB Integration with Clear
#
# Clear supports natively postgres jsonb columns
#
# Functions can be used calling or including Clear::SQL::JSONB methods as helper methods:
#
# ```crystal
# class MyClass
#   include Clear::SQL::JSONB
#
#   def create_sql_with_json
#     Clear::SQL.select.where(jsonb_any_exists?("attributes", ["a", "b", "c"]))
#     # ^-- operator `?|`, if the keys a, b or c exists in the jsonb table 'attributes'
#   end
# end
# ```
# Moreover, jsonb is directly integrated into the Expression Engine.
# For that, just call `jsonb` after a variable to activate the methods:
#
# ### Filter by jsonb
#
# ```crystal
# Product.query.where { (attributes.jsonb("category") == "Book") & (attributes.jsonb("author.name") == "Philip K. Dick") }
# # ^-- Will produce optimized for gin index jsonb filter query:
# # WHERE attributes @> '{"category": "Book", "author": {"name": "Philip K. Dick"} }'::jsonb
# ```
#
#
require "json"

require "./**"

module Clear::SQL::JSONB
  extend self

  alias JSONBKey = JSONBHash | Clear::Expression::AvailableLiteral
  alias JSONBHash = Hash(String, JSONBKey)

  # Transform a key to a hash
  def jsonb_k2h(key : String, value : JSONBKey) : JSONBHash
    jsonb_arr2h(jsonb_k2a(key), value)
  end

  # jsonb `?|` operator
  # Do any of these array strings exist as top-level keys?
  #
  def jsonb_any_exists?(field, keys : Array(String))
    {field, "array[" + keys.map { |x| Clear::SQL.sanitize(x) }.join(",") + "]"}.join(" ?| ")
  end

  # Does the string exist as a top-level key within the JSON value?
  def jsonb_exists?(field, value)
    {field, Clear::SQL.sanitize(value)}.join(" ? ")
  end

  # jsonb `?&` operator
  # Do all of these array strings exist as top-level keys?
  def jsonb_all_exists?(field, keys : Array(String))
    {field, "array[" + keys.map { |x| Clear::SQL.sanitize(x) }.join(",") + "]"}.join(" ?& ")
  end

  # :nodoc:
  def jsonb_arr2h(key : Array(String), value : JSONBKey, idx = 0) : JSONBHash
    h = Hash(String, JSONBKey).new

    if idx == key.size - 1
      h[key[idx]] = value
    else
      h[key[idx]] = jsonb_arr2h(key, value, idx + 1)
    end

    h
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

    arr
  end

  # Test equality using the `@>` operator
  #
  # ```crystal
  # jsonb_eq("data.sub.key", "value")
  # ```
  #
  # => `data @> '{"sub": {"key": "value"}}' `
  def jsonb_eq(field, key, value)
    arr = jsonb_k2a(key)

    if arr.empty?
      {field, Clear::Expression[value]}.join(" = ")
    else
      {field, Clear::Expression[jsonb_arr2h(arr, value).to_json]}.join(" @> ")
    end
  end

  def jsonb_resolve(field, arr : Array(String), cast = nil) : String
    return field if arr.empty?
    o = ([field] + Clear::Expression[arr]).join("->")
    o += "::#{cast}" if cast
    o
  end

  # Return text selector for the field/key :
  #
  # ```crystal
  # jsonb_text("data", "sub.key").like("user%")
  # # => "data->'sub'->>'key' LIKE 'user%'"
  # ```
  #
  def jsonb_resolve(field, key : String, cast = nil)
    arr = jsonb_k2a(key)
    jsonb_resolve(field, arr, cast)
  end
end

class Clear::Expression::Node
  include Clear::Expression::JSONB::Node
end
