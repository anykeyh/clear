# This module declare all the methods and macro related to deserializing json in `Clear::Model`
module Clear::Model::JSONDeserialize
  macro included
    macro included # When included into Model
      macro inherited # Polymorphism
        macro finished
          columns_to_instance_vars
        end
      end

      macro finished
        columns_to_instance_vars
      end
    end
  end
end

# Used internally to deserialise json
macro columns_to_instance_vars
  # :nodoc:
  struct Assigner
    include JSON::Serializable

    {% for name, settings in COLUMNS %}
      @[JSON::Field(presence: true)]
      getter {{name.id}} : {{settings[:type]}} {% unless settings[:type].resolve.nilable? %} | Nil {% end %}
      @[JSON::Field(ignore: true)]
      getter? {{name.id}}_present : Bool
    {% end %}

    # Create a new empty model and fill the columns with object's instance variables
    # Trusted flag set to true will allow mass assignment without protection
    def create(trusted : Bool)
      assign_columns({{@type}}.new, trusted)
    end

    # Update the inputted model and assign the columns with object's instance variables
    # Trusted flag set to true will allow mass assignment without protection
    def update(model, trusted : Bool)
      assign_columns(model, trusted)
    end

    macro finished
      # Assign properties to the model inputted with object's instance variables
      # Trusted flag set to true will allow mass assignment without protection
      protected def assign_columns(model, trusted : Bool)
        {% for name, settings in COLUMNS %}
          if ({{ settings[:mass_assign] }} || trusted) && self.{{name.id}}_present?
            %value = self.{{name.id}}
            {% if settings[:type].resolve.nilable? %}
              model.{{name.id}} = %value
            {% else %}
              model.{{name.id}} = %value unless %value.nil?
            {% end %}
          end
        {% end %}

        model
      end
    end
  end

  # Create a new empty model and fill the columns from json. Returns the new model
  #
  # Trusted flag set to true will allow mass assignment without protection, FALSE by default
  def self.from_json(string_or_io : String | IO, trusted : Bool = false)
    Assigner.from_json(string_or_io).create(trusted)
  end

  # Create a new model from json and save it. Returns the model.
  #
  # The model may not be saved due to validation failure;
  # check the returned model `errors?` and `persisted?` flags.
  # Trusted flag set to true will allow mass assignment without protection, FALSE by default
  def self.create_from_json(string_or_io : String | IO, trusted : Bool = false)
    mdl = self.from_json(string_or_io, trusted)
    mdl.save
    mdl
  end

  # Create a new model from json and save it. Returns the model.
  #
  # Returns the newly inserted model
  # Raises an exception if validation failed during the saving process.
  # Trusted flag set to true will allow mass assignment without protection, FALSE by default
  def self.create_from_json!(string_or_io : String | IO, trusted : Bool = false)
    self.from_json(string_or_io, trusted).save!
  end

  # Set the fields from json passed as argument
  # Trusted flag set to true will allow mass assignment without protection, FALSE by default
  def set_from_json(string_or_io : String | IO, trusted : Bool = false)
    Assigner.from_json(string_or_io).update(self, trusted)
  end

  # Set the fields from json passed as argument and call `save` on the object
  # Trusted flag set to true will allow mass assignment without protection, FALSE by default
  def update_from_json(string_or_io : String | IO, trusted : Bool = false)
    mdl = set_from_json(string_or_io, trusted)
    mdl.save
    mdl
  end

  # Set the fields from json passed as argument and call `save!` on the object
  # Trusted flag set to true will allow mass assignment without protection, FALSE by default
  def update_from_json!(string_or_io : String | IO, trusted : Bool = false)
    set_from_json(string_or_io, trusted).save!
  end
end
