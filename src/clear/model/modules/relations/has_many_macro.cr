# :nodoc:
module Clear::Model::Relations::HasManyMacro

  # has many
  macro generate(self_type, relation)
    {%
      foreign_key = (relation[:foreign_key] || "#{self_type.stringify.underscore.gsub(/::/, "_").id}_id").id

      method_name = relation[:name].id
      relation_type = relation[:type]
    %}

    __define_association_cache__({{method_name}}, Array({{relation_type}}))

    def self.__relation_filter_{{method_name}}__(query)
      query.inner_join({{self_type}}.table){ var( {{self_type}}.table, {{self_type}}.__pkey__ ) == var( {{relation_type}}.table, "{{foreign_key}}" ) }
    end

    # :nodoc:
    def self.__relation_key_table_{{method_name}}__ : Tuple(String, String)
      {
        {{relation_type}}.table.to_s,
        {{"#{foreign_key}"}}
      }
    end

    RELATION_FILTERS["{{method_name}}"] = -> (x : Clear::SQL::SelectBuilder) { __relation_filter_{{method_name}}__(x) }

    # The method {{method_name}} is a `has_many` relation
    # to {{relation_type}}
    def {{method_name}} : {{ relation_type }}::Collection
      cache = @cache

      %foreign_key = {{"#{foreign_key}"}}

      query = {{relation_type}}.query
        .tags({ %foreign_key => self.__pkey_column__.to_sql_value })
        .where{ var({{relation_type}}.table, %foreign_key) == self.__pkey__ }

      if @_cached_{{method_name}}
        query.with_cached_result(@_cached_{{method_name}})
      elsif ( cache && cache.active?("{{method_name}}") )
        @_cached_{{method_name}} = cache.hit("{{method_name}}", self.__pkey_column__.to_sql_value, {{relation_type}})
        # This relation will trigger the cache if it exists
        query.with_cached_result(@_cached_{{method_name}})
      end

      {%
        # Allow to add an element in this collection by changing the `foreign_key`
        # value of the distant model.
      %}
      query.append_operation = -> (x : {{relation_type}}) do
        x.{{foreign_key}} = self.__pkey__
        self.save! unless self.persisted?
        x.reset(query.tags).save!
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

          %key = {{self_type}}.__pkey__
          %table = {{self_type}}.table

          #SELECT * FROM foreign WHERE foreign_key IN ( SELECT primary_key FROM users )
          sub_query = self.dup.clear_select.select("#{%table}.#{%key}")

          qry = {{relation_type}}.query.where{ var({{relation_type}}.table, %foreign_key).in?(sub_query) }
          block.call(qry)

          @cache.active "{{method_name}}"

          h = {} of Clear::SQL::Any => Array({{relation_type}})

          qry.each(fetch_columns: true) do |mdl|
            unless h[mdl.attributes[%foreign_key]]?
              h[mdl.attributes[%foreign_key]] = [] of {{relation_type}}
            end

            h[mdl.attributes[%foreign_key]] << mdl
          end

          h.each{ |key, value| @cache.set("{{method_name}}", key, value) }
        end

        self
      end

      def with_{{method_name}}(fetch_columns = false)
        with_{{method_name}}(fetch_columns){ } #empty block
      end
    end

  end
end
