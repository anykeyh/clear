# :nodoc:
module Clear::Model::Relations::HasOneMacro

  macro __filter_relation_has_one__(self_class, relation, final, query)
    {% begin %}
      {%
        foreign_key = (relation[:foreign_key] || "#{method_name.stringify.underscore}_id").id
        relation_type = relation[:type]
      %}

      {{query}}.inner_join{ var( {{self_class}}.table, {{self_class}}.__pkey__ ) == var( {{relation_type}}.table, "{{foreign_key}}" ) }
    {% end %}
  end

  # :nodoc:
  # Write down the code for Has one relation
  macro generate(self_type, relation)
    {% begin %}
      {%
        foreign_key = (relation[:foreign_key] || "#{self_type.stringify.underscore.gsub(/::/, "_").id}_id").id

        method_name = relation[:name].id
        relation_type = relation[:type]

        primary = relation[:primary]

        nilable = relation[:nilable]
      %}

      __define_association_cache__({{method_name}}, {{relation_type}})

      def self.__relation_filter_{{method_name}}__(query)
        query.inner_join({{self_type}}.table){ var( {{self_type}}.table, {{self_type}}.__pkey__ ) == var( {{relation_type}}.table, "{{foreign_key}}" ) }
      end

      RELATION_FILTERS["{{method_name}}"] = -> (x : Clear::SQL::SelectBuilder) { __relation_filter_{{method_name}}__(x) }

      # The method {{method_name}} is a `has_one` relation
      #   to {{relation_type}}
      def {{method_name}} : {{ relation_type }}{{ nilable ? "?".id : "".id }}
        if cached = @_cached_{{method_name}}
          # Local cache
          cached
        elsif @cache.try &.active? "{{method_name}}"
          # eager load cache
          cache = @cache.not_nil!

          model = @_cached_{{method_name}} = cache.hit("{{method_name}}",
            self.__pkey_column__.to_sql_value, {{relation_type}} ).first?

          {% if !nilable %} raise Clear::SQL::RecordNotFoundError.new if model.nil? {% end %}

          model
        else
          # no cache: load again
          @_cached_{{method_name}} =
            {{relation_type}}.query
              .where{ var({{relation_type}}.table, "{{foreign_key}}") == self.__pkey__ }
              .{{ !nilable ? "first!".id : "first".id }}
        end
      end

      {% if nilable %}
        def {{method_name}}! : {{relation_type}}
          if model = self.{{method_name}}.nil?
            raise Clear::SQL::RecordNotFoundError.new
          end

          model
        end # /  *!
      {% end %}

      def {{method_name}}=(model : {{ relation_type }}{{ nilable ? "?".id : "".id }})
        @_cached_{{method_name}} = model
        save! unless persisted?
        model.try &.{{foreign_key}}=(self.__pkey__)
        model
      end

      class Collection
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

            qry.each(fetch_columns: fetch_columns) do |mdl|
              @cache.set("{{method_name}}", mdl.{{foreign_key}}, [mdl])
            end
          end

          self
        end # / with_*

        def with_{{method_name}}(fetch_columns = false) : self
          with_{{method_name}}(fetch_columns){}
          self
        end # / with_*

      end # / Collection
    {% end %} # / begin block
  end # / macro


    # # Return the related model `{{method_name}}`.
    # #
    # # This relation is of type one to zero or one [1, 0..1]
    # # between {{relation_type}} and {{self_type}}
    # #
    # # If the relation hasn't been cached, will call a `select` SQL operation.
    # # Otherwise, will try to find in the cache.
    # def {{method_name}} : {{relation_type}}?
    #   %primary_key = {{(primary_key || "__pkey__").id}}
    #   %foreign_key =  {{foreign_key}} || ( self.class.table.to_s.singularize + "_id" )

    #   {{relation_type}}.query.where{ raw(%foreign_key) == %primary_key }.first
    # end

    # # Return the related model `{{method_name}}`,
    # # but throw an error if the model is not found.
    # def {{method_name}}! : {{relation_type}}
    #   {{method_name}}.not_nil!
    # end

end