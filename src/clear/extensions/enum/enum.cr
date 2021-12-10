module Clear
  class IllegalEnumValueError < Exception
  end

  # Clear::Enum wrap the enums used in PostgreSQL.
  # See `Clear.enum` macro helper.
  abstract struct Enum
    include Clear::Expression::Literal

    @value : String

    protected def initialize(@value)
    end

    def to_s : String
      @value.to_s
    end

    def to_sql : String
      @value.to_sql
    end

    def to_json(json : JSON::Builder)
      json.string(@value)
    end

    def ==(x)
      super(x) || @value == x
    end

    module Converter(T)
      def self.to_column(x) : T?
        case x
        when String
          T.authorized_values[x]
        when Nil
          nil
        else
          raise converter_error(x.class.name, "Enum: #{T.class.name}")
        end
      end
    end
  end

  # ## Enum
  #
  # Clear offers full support of postgres enum strings.
  #
  # ### Example
  #
  # Let's say you need to define an enum for genders:
  #
  # ```crystal
  # # Define the enum
  # Clear.enum MyApp::Gender, "male", "female" # , ...
  # ```
  #
  # In migration, we tell Postgres about the enum:
  #
  # ```crystal
  # create_enum :gender, MyApp::Gender # < Create the new type `gender` in the database
  #
  # create_table :users do |t|
  #   # ...
  #   t.gender "gender" # < first `gender` is the type of column, while second is the name of the column
  # end
  # ```
  #
  # Finally in your model, simply add the enum as column:
  #
  # ```crystal
  # class User
  #   include Clear::Model
  #   # ...
  #
  #   column gender : MyApp::Gender
  # end
  # ```
  #
  # Now, you can assign the enum:
  #
  # ```crystal
  # u = User.new
  # u.gender = MyApp::Gender::Male
  # ```
  #
  # You can dynamically check and build the enumeration values:
  #
  # ```crystal
  # MyApp::Gender.authorized_values # < return ["male", "female"]
  # MyApp::Gender.all               # < return [MyApp::Gender::Male, MyApp::Gender::Female]
  #
  # MyApp::Gender.from_string("male")    # < return MyApp::Gender::Male
  # MyApp::Gender.from_string("unknown") # < throw Clear::IllegalEnumValueError
  #
  # MyApp::Gender.valid?("female")  # < Return true
  # MyApp::Gender.valid?("unknown") # < Return false
  # ```
  #
  # However, you cannot write:
  #
  # ```crystal
  # u = User.new
  # u.gender = "male"
  # ```
  #
  # But instead:
  #
  # ```crystal
  # u = User.new
  # u.gender = MyApp::Gender::Male
  # ```
  macro enum(name, *values, &block)
    struct {{name.id}} < ::Clear::Enum
      {% for i in values %}
        {{i.camelcase.id}} = {{name.id}}.new("{{i.id}}")
      {% end %}

      {% begin %}
        AUTHORIZED_VALUES = {
        {% for i in values %}
          "{{i.id}}" => {{i.camelcase.id}},
        {% end %}
        }
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

      def self.valid?(x)
        AUTHORIZED_VALUES[x]?
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
              raise Clear::ErrorMessages.converter_error(x.class.name, "::\{{@type}}")
            end
          end

          def self.to_db(x : ::\{{@type}}?)
            x.to_s
          end
        end

        Clear::Model::Converter.add_converter("\{{@type}}", ::Clear::Model::Converter::\{{@type}}Converter)
      end

      {{yield}}
    end


  end
end
