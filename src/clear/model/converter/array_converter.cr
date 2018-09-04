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
    case x
    when Nil
      return nil
    when ::{{exp.id}}
      return [x]
    when Array(::PG::{{exp.id}}Array)
      return x.map do |i|
        case i
        when ::{{exp.id}}
          i
        else
          nil
        end
      end.compact
    else
      if arr = ::JSON.parse(x.to_s).as_a?
        return arr.map{ |x| x.as_{{k.id}} }
      end

      return nil
    end
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
