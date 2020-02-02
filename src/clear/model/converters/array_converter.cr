require "./base"

{% begin %}
{% # Mapping of the Array type to array in postgresql.
 typemap = {
   "Bool"    => "boolean[]",
   "String"  => "text[]",
   "Float32" => "real[]",
   "Float64" => "double precision[]",
   "Int32"   => "int[]",
   "Int64"   => "bigint[]",
 } %}
{% for k, exp in {
                   bool: Bool,
                   s:    String,
                   f32:  Float32,
                   f:    Float64,
                   i:    Int32,
                   i64:  Int64,
                 } %}

module Clear::Model::Converter::ArrayConverter{{exp.id}}
  def self.to_column(x) : Array(::{{exp.id}})?
    case x
    when Nil
      return nil
    when ::{{exp.id}}
      return [x]
    when Array(::{{exp.id}})
      return x
    when Array(::PG::{{exp.id}}Array)
      return x.map do |i|
        case i
        when ::{{exp.id}}
          i
        else
          nil
        end
      end.compact
    when Array(::JSON::Any)
      return x.map(&.as_{{k.id}})
    when ::JSON::Any
      if arr = x.as_a?
        return arr.map(&.as_{{k.id}})
      else
        raise "Cannot convert from #{x.class} to Array({{exp.id}}) [1]"
      end
    else
      raise "Cannot convert from #{x.class} to Array({{exp.id}}) [2]"
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
      {% t = typemap["#{exp.id}"] %}
    if x
      Clear::Expression.unsafe({"Array[", to_string(x), "]::{{t.id}}"}.join)
    else
      nil
    end
  end

end

Clear::Model::Converter.add_converter("Array({{exp.id}})", Clear::Model::Converter::ArrayConverter{{exp.id}})
Clear::Model::Converter.add_converter("Array({{exp.id}} | Nil)", Clear::Model::Converter::ArrayConverter{{exp.id}})

{% end %}
{% end %}
