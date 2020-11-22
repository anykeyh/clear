# :nodoc:
module Clear::Model::Relations::HasManyThroughMacro

  # has_many through
  macro generate(self_type, relation, through_rel)
    {%
      foreign_key = (relation[:foreign_key] || "#{self_type.stringify.underscore.gsub(/::/, "_").id}_id").id

      method_name = relation[:name].id
      relation_type = relation[:type]

      to = relation[:relation]
      to = "#{to.id}" if to
    %}

    __define_association_cache__({{method_name}}, Array({{relation_type}}) )

    def self.__relation_filter_{{method_name}}__(query)
      {% if to %}
        %to = {{to}}
      {% else %}
        %to = "{{method_name}}".singularize
      {% end %}

      {{ through_rel[:type] }}.__call_relation_filter__(%to, query)
      self.__call_relation_filter__( "{{through_rel[:name].id}}", query)
    end

    # :nodoc:
    def self.__relation_key_table_{{method_name}}__ : Tuple(String, String)
      self.__relation_key_table_{{through_rel[:name].id}}__
    end

    __on_init__ do
      {{self_type}}::RELATION_FILTERS["{{method_name}}"] = -> (x : Clear::SQL::SelectBuilder) { __relation_filter_{{method_name}}__(x) }
    end

    def {{method_name}} : {{relation_type}}::Collection

      query = {{relation_type}}.query.distinct.select("#{{{relation_type}}.table}.*")

      self.class.__relation_filter_{{method_name}}__(query)

      query.where{ var({{self_type}}.table, {{self_type}}.__pkey__) == self.__pkey__ }

      cache = @cache

      if cache && cache.active?("{{method_name}}")
        arr = cache.hit("{{method_name}}", self.__pkey_column__.to_sql_value, {{relation_type}})
        query.with_cached_result(arr)
      end

      query
    end

    # Addition of the method for eager loading and N+1 avoidance.
    class Collection
          # Eager load the has many relation {{method_name}}.
      # Use it to avoid N+1 queries.
      def with_{{method_name}}(fetch_columns = false, &block : {{relation_type}}::Collection -> ) : self
        before_query do
          %foreign_key = {{"#{foreign_key}"}}

          %sub_query_key = { {{self_type}}.table, {{self_type}}.__pkey__ }.map{ |x| Clear::SQL.escape(x) }.join(".")
          sub_query = self.dup.clear_select.select(%sub_query_key)

          %table, %key = {{self_type}}.__relation_key_table_{{method_name}}__
          %target = Clear::SQL.escape(%table) + "." + Clear::SQL.escape(%key)
          query = {{relation_type}}.query.distinct.select("#{{{relation_type}}.table}.*").select( __own_key__: %sub_query_key )

          self.item_class.__relation_filter_{{method_name}}__(query)
          query.where { raw(%sub_query_key).in?(sub_query) }

          block.call(query)

          @cache.active "{{method_name}}"

          h = {} of Clear::SQL::Any => Array({{relation_type}})

          query.each(fetch_columns: true) do |mdl|
            key = mdl.attributes["__own_key__"]
            unless h[key]?
              h[key] = [] of {{relation_type}}
            end

            h[key] << mdl
          end

          h.each{ |key, value|
            @cache.set("{{method_name}}", key, value)
          }
        end

        self
      end

      def with_{{method_name}}(fetch_columns = false)
        with_{{method_name}}(fetch_columns){ } #empty block
      end
    end
  end
end
