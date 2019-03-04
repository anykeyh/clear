require "./base"

module Clear::Model::Converter
  # Macro used to generate conveniently all conversion for
  # numbers (different bitsize, signed/unsigned etc...)
  private macro number_converter(t)
    # Convert from and to {{t}}
    class ::Clear::Model::Converter::{{t}}Converter
      def self.to_column(x) : {{t}}?
        case x
        when Nil
          nil
        when Number
          {{t}}.new(x)
        else
          {{t}}.new(x.to_s)
        end
      end

      def self.to_db(x : {{t}}?)
        x
      end
    end

    Clear::Model::Converter.add_converter("{{t}}", ::Clear::Model::Converter::{{t}}Converter)
  end

  number_converter(Int8)
  number_converter(Int16)
  number_converter(Int32)
  number_converter(Int64)

  number_converter(UInt8)
  number_converter(UInt16)
  number_converter(UInt32)
  number_converter(UInt64)

  number_converter(Float32)
  number_converter(Float64)

  number_converter(BigInt)
  number_converter(BigFloat)
end
