macro columns_to_instance_vars
  struct Assigner
    include JSON::Serializable

    {% for name, settings in COLUMNS %}
      getter {{name.id}} : {{settings[:type]}}?
    {% end %}

    def to_create
      parse_from_json({{@type}}.new) # Loop through instance variables and assign to the newly created orm instance
    end

    def to_update(to_update_model)
      parse_from_json(to_update_model) # Loop through instance variables and assign to the orm instance you are updating
    end

    macro finished
      def parse_from_json(model)
        {% for name, settings in COLUMNS %}
          model.{{name.id}} = @{{name.id}}.not_nil! unless @{{name.id}}.nil?
        {% end %}

        model
      end
    end
  end

  def self.from_json(string_or_io : String | IO)
    Assigner.from_json(string_or_io)
  end

  def self.new(string_or_io : String | IO)
    Assigner.from_json(string_or_io).to_create
  end

  def self.create(string_or_io : String | IO)
    self.new(string_or_io).save
  end

  def self.create!(string_or_io : String | IO)
    self.new(string_or_io).save!
  end

  def set(string_or_io : String | IO)
    Assigner.from_json(string_or_io).to_update(self)
  end

  def update(string_or_io : String | IO)
    set(string_or_io).save
  end

  def update!(string_or_io : String | IO)
    set(string_or_io).save!
  end
end

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
