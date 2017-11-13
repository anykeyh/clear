module Clear::Model::HasRelations
  # ```
  # class Model
  #   include Clear::Model
  #
  #   has posts : Array(Post), [ foreign_key: Model.underscore_name + "_id", no_cache : false]
  #
  #   has passport : Passport
  # ```
  macro has(name, foreign_key = nil, no_cache = false, primary_key = nil)
    {% if name.type.is_a?(Generic) && "#{name.type.name}" == "Array" %}
      {% if name.type.type_vars.size != 1 %}
        {% raise "has method accept only Array(Model) for has many behavior. Unions are not accepted" %}
      {% end %}

      {% t = name.type.type_vars[0].resolve %}

      {% unless t < Clear::Model %}
        {% raise "Use `has` with an Array of model, or a single model. `#{t}` is not a valid model" %}
      {% end %}
      # Here the has many code
      def {{name.var.id}} : {{t}}::Collection
        %primary_key = {{(primary_key || "pkey").id}}
        %foreign_key =  {{foreign_key}} || ( self.class.table.to_s.singularize + "_id" )
        {{t}}.query.tags({ "#{%foreign_key}" => "#{%primary_key}" }).where{ raw(%foreign_key) == %primary_key }
      end
    {% else %}
      # Here the has one code.
      {% t = name.type %}
      def {{name.var.id}} : {{t}}?
        %primary_key = {{(primary_key || "pkey").id}}
        %foreign_key =  {{foreign_key}} || ( self.class.table.to_s.singularize + "_id" )

        Clear::Model::Cache.instance.hit( "{{t.id}}.{{name.var.id}}",
          %primary_key, {{t}}
        ) do
          [ {{t}}.query.where{ raw(%foreign_key) == %primary_key }.first ].compact
        end.first?


      end

      # Adding the eager loading
      class Collection
        def with_{{name.var.id}} : self
          before_query do
            %primary_key = {{(primary_key || "#{t}.pkey").id}}
            %foreign_key =  {{foreign_key}} || ( {{@type}}.table.to_s.singularize + "_id" )

            #SELECT * FROM foreign WHERE foreign_key IN ( SELECT primary_key FROM users )
            sub_query = self.dup.clear_select.select("#{%primary_key}")

            {{t}}.query.where{ raw(%foreign_key).in?(sub_query) }.each do |mdl|
              Clear::Model::Cache.instance.set(
                "{{t.id}}.{{name.var.id}}", mdl.pkey, [mdl]
              )
            end
          end

          self
        end
      end


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
      Clear::Model::Cache.instance.hit( "{{t.id}}.{{name.var.id}}",
        self.{{foreign_key.id}}, {{t}}
      ) do
        [ {{t}}.query.where{ raw({{t}}.pkey) == self.{{foreign_key.id}} }.first ].compact
      end.first?
    end

    def {{name.var.id}}! : {{t}}
      {{name.var.id}}.not_nil!
    end

    def {{name.var.id}}=(x : {{t}}?)
      @{{foreign_key.id}} = x
      @{{foreign_key.id}}_field.value = x.pkey
    end

    # Adding the eager loading
    class Collection
      def with_{{name.var.id}} : self
        before_query do
          sub_query = self.dup.clear_select.select("{{foreign_key.id}}")
          #{{t}}.query.where{ raw({{t}}.pkey) == self.{{foreign_key.id}} }.first ]
          #SELECT * FROM users WHERE id IN ( SELECT user_id FROM posts )
          {{t}}.query.where{ raw({{t}}.pkey).in?(sub_query) }.each do |mdl|
            Clear::Model::Cache.instance.set(
              "{{t.id}}.{{name.var.id}}", mdl.pkey, [mdl]
            )
          end
        end

        self
      end
    end

  end
end
