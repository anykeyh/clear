require "pg"
require "json"

{% for k, exp in {
                   bool: Bool,
                   s:    String,
                   f32:  Float32,
                   f:    Float64,
                   i:    Int32,
                   i64:  Int64,
                 } %}

class Clear::Model::Converter::ArrayConverter_{{exp.id}}_
  def self.to_column(x) : Array(::{{exp.id}})?
    if x
      if arr = ::JSON.parse(x.to_s).as_a?
        arr.map{ |x| x.as_{{k.id}} }
      end
    else
      nil
    end
    # case x
    # when Array(::{{exp.id}})
    #   x.as(Array(::{{exp.id}}))
    # when Nil
    #   x
    # else
    #   raise "Cannot convert #{x.class} to {{exp.id}}"
    # end
  end

  def self.to_string( x ) : String
    case x
    when Array
      x.map{ |it| to_string(it) }.join(", ")
    else
      ""+Clear::Expression[x]
    end
  end

  def self.to_db(x : Array(::{{exp.id}})?) : Clear::SQL::Any
    if x
      Clear::Expression.unsafe({"Array[", to_string(x), "]"}.join)
    else
      nil
    end
  end
end

{% end %}
