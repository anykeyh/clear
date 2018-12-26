# :nodoc:
module Clear::Model::Relations::HasManyMacro

    # has many
  macro generate(self_type, method_name, relation_type, foreign_key = nil, primary_key = nil)
    # The method {{method_name}} is a `has_many` relation
    #   to {{relation_type}}
    def {{method_name}} : {{relation_type}}::Collection
      %primary_key = {{(primary_key || "pkey").id}}
      %foreign_key =   {% if foreign_key %} "{{foreign_key}}" {% else %} (self.class.table.to_s.singularize + "_id") {% end %}

      cache = @cache
      if cache && cache.active?("{{method_name}}")
        arr = cache.hit("{{method_name}}", %primary_key, {{relation_type}})

        # This relation will trigger the cache if it exists
        {{relation_type}}.query \
          .tags({ "#{%foreign_key}" => "#{%primary_key}" }) \
          .where{ raw(%foreign_key) == %primary_key }
          .with_cached_result(arr)
      else
        {{relation_type}}.query \
          .tags({ "#{%foreign_key}" => "#{%primary_key}" }) \
        .where{ raw(%foreign_key) == %primary_key }
      end
    end

    # Addition of the method for eager loading and N+1 avoidance.
    class Collection
      # Eager load the has many relation {{method_name}}.
      # Use it to avoid N+1 queries.
      def with_{{method_name}}(fetch_columns = false, &block : {{relation_type}}::Collection -> ) : self
        before_query do
          %primary_key = {{(primary_key || "#{relation_type}.pkey").id}}
          %foreign_key =   {% if foreign_key %} "{{foreign_key}}" {% else %} ({{self_type}}.table.to_s.singularize + "_id") {% end %}

          #SELECT * FROM foreign WHERE foreign_key IN ( SELECT primary_key FROM users )
          sub_query = self.dup.clear_select.select("#{{{self_type}}.table}.#{%primary_key}")

          qry = {{relation_type}}.query.where{ raw(%foreign_key).in?(sub_query) }
          block.call(qry)

          @cache.active "{{method_name}}"

          h = {} of Clear::SQL::Any => Array({{relation_type}})


          qry.each(fetch_columns: true) do |mdl|
            unless h[mdl.attributes[%foreign_key]]?
              h[mdl.attributes[%foreign_key]] = [] of {{relation_type}}
            end

            h[mdl.attributes[%foreign_key]] << mdl
          end

          h.each do |key, value|
            @cache.set("{{method_name}}", key, value)
          end
        end

        self
      end

      def with_{{method_name}}(fetch_columns = false)
        with_{{method_name}}(fetch_columns){|q|} #empty block
      end
    end

  end
end