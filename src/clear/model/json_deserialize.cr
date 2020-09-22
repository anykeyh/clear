# This module declare all the methods and macro related to deserializing json in `Clear::Model`
module Clear::Model::JSONDeserialize
  macro included
    macro included # When included into Model
      macro inherited #Polymorphism
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
    def create
      assign_columns({{@type}}.new)
    end

    # Update the inputted model and assign the columns with object's instance variables
    def update(model)
      assign_columns(model)
    end

    macro finished
      # Assign properties to the model inputted with object's instance variables
      protected def assign_columns(model)
        {% for name, settings in COLUMNS %}
          if self.{{name.id}}_present?
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

  # Create a new empty model and fill the columns from json
  #
  # Returns the new model
  def self.from_json(string_or_io : String | IO)
    Assigner.from_json(string_or_io).create
  end

  # Create a new model from json and save it. Returns the model.
  #
  # The model may not be saved due to validation failure;
  # check the returned model `errors?` and `persisted?` flags.
  def self.create_from_json(string_or_io : String | IO)
    mdl = self.from_json(string_or_io)
    mdl.save
    mdl
  end

  # Create a new model from json and save it. Returns the model.
  #
  # Returns the newly inserted model
  # Raises an exception if validation failed during the saving process.
  def self.create_from_json!(string_or_io : String | IO)
    self.from_json(string_or_io).save!
  end

  # Set the fields from json passed as argument
  def set_from_json(string_or_io : String | IO)
    Assigner.from_json(string_or_io).update(self)
  end

  # Set the fields from json passed as argument and call `save` on the object
  def update_from_json(string_or_io : String | IO)
    mdl = set_from_json(string_or_io)
    mdl.save
    mdl
  end

  # Set the fields from json passed as argument and call `save!` on the object
  def update_from_json!(string_or_io : String | IO)
    set_from_json(string_or_io).save!
  end
end
