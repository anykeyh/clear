module Clear::Model::HasRelations
  # ```
  # class Model
  #   include Clear::Model
  #
  #   has posts : Array(Post), [ foreign_key: Model.underscore_name + "_id", no_cache : false]
  #
  #   has passport : Passport
  # ```
  #
  macro has(name, foreign_key = nil, no_cache = false, primary_key = nil)
    {% if name.type.is_a?(Generic) && "#{name.type.name}" == "Array" %}
      {% if name.type.type_vars.size != 1 %}
        {% raise "has method accept only Array(Model) for has many behavior. Unions are not accepted" %}
      {% end %}

      {% t = name.type.type_vars[0].resolve %}
      {% if t < Clear::Model %}
        # Here the has many code
        def {{name.var.id}} : {{t}}::Collection
          %primary_key = {{(primary_key || "pkey").id}}
          %foreign_key =  {{foreign_key}} || ( self.class.table.to_s.singularize + "_id" )
          {{t}}.query.where{ raw(%foreign_key) == %primary_key }
        end
      {% else %}
        {% raise "Use `has` with an Array of model, or a single model. `#{t}` is not a valid model" %}
      {% end %}
    {% else %}
      {% t = name.type %}
      def {{name.var.id}} : {{t}}?
        %primary_key = {{(primary_key || "pkey").id}}
        %foreign_key =  {{foreign_key}} || ( self.class.table.to_s.singularize + "_id" )
        {{t}}.query.where{ raw(%foreign_key) == %primary_key }.first
      end
      # Here the has one code.
    {% end %}
  end

  # ```
  # class Model
  #   include Clear::Model
  #   belongs_to user : User, foreign_key: "the_user_id"
  #
  # ```
  macro belongs_to(name, foreign_key = nil, no_cache = false, key_type = Int32?)
    {% t = name.type %}
    {% foreign_key = foreign_key || t.stringify.underscore + "_id" %}

    column {{foreign_key.id}} : {{key_type}}

    def {{name.var.id}} : {{t}}?
      @{{foreign_key.id}} ||
        {{t}}.query.where{ raw({{t}}.pkey) == self.{{foreign_key.id}} }.first
    end

    def {{name.var.id}}=(x : {{t}}?)
      @{{foreign_key.id}} = x
      @{{foreign_key.id}}_field.value = x.pkey
    end
  end
end
