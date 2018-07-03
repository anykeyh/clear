module Clear
  class IllegalEnumValueError < Exception
  end

  # The mother of all enums
  abstract struct Enum
    include Clear::Expression::Literal

    @value : String

    protected def initialize(@value)
    end

    def to_s
      @value.to_s
    end

    def to_sql
      @value.to_sql
    end

    def to_json(x = nil)
      @value
    end

    def ==(x)
      super(x) || @value == x
    end

    module Converter(T)
      def self.to_column(x) : T?
        case x
        when String
          return T.authorized_values[x]
        when Nil
          return nil
        else
          raise "Cannot convert #{x.class} to Enum : #{T.class}"
        end
      end
    end
  end

  # Construct a database enum field.
  # example:
  # ```crystal
  # Clear.enum(MyApp::Gender, "male", "female")
  # ```
  #
  # in your model:
  # ```crystal
  # column gender: MyApp::Gender
  # ```
  macro enum(name, *values)
    struct {{name.id}} < ::Clear::Enum
      AUTHORIZED_VALUES = {} of String => {{name.id}}

      {% for i in values %}
        {{i.camelcase.id}} = {{name.id}}.new("{{i.id}}")
        AUTHORIZED_VALUES["{{i.id}}"] = {{i.camelcase.id}}
      {% end %}

      # Return the enum with the string passed as parameter.
      # Throw Clear::IllegalEnumValueError if the string is not found.
      def self.from_string(str : String)
        AUTHORIZED_VALUES[str]? || raise ::Clear::IllegalEnumValueError.new("Illegal enum value for `#{self.class}`: '#{str}'")
      end

      # Return the list of authorized values
      def self.authorized_values
        AUTHORIZED_VALUES.keys
      end

      def self.all
        AUTHORIZED_VALUES.values
      end

      macro finished
        module ::Clear::Model::Converter::\{{@type}}Converter
          def self.to_column(x) : ::\{{@type}}?
            case x
            when Nil
              nil
            when ::\{{@type}}
              x
            when String
              ::\{{@type}}.from_string(x)
            when Slice(UInt8)
              ::\{{@type}}.from_string(String.new(x))
            else
              raise "Cannot convert #{x.class} to ::{{@type}}"
            end
          end

          def self.to_db(x : ::\{{@type}}?)
            x.to_s
          end
        end
      end

    end

  end
end
