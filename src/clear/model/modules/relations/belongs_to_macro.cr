# :nodoc:
module Clear::Model::Relations::BelongsToMacro
  macro generate(self_type, relation)
    {% begin %}
      {%
        method_name = relation[:name].id
        relation_type = relation[:type]

        foreign_key = (relation[:foreign_key] || "#{method_name.stringify.underscore.id}_id").id

        foreign_key_type = relation[:foreign_key_type].id

        presence = relation[:presence]
        primary = relation[:primary]

        nilable = relation[:nilable]

        mass_assign = relation[:mass_assign]
      %}

      __define_association_cache__({{method_name}}, {{relation_type}})

      column {{foreign_key}} : {{foreign_key_type}}{{ nilable ? "?".id : "".id }}, primary: {{primary}}, presence: false, mass_assign: {{mass_assign}}

      # :nodoc:
      def self.__relation_filter_{{method_name}}__(query)
        query.inner_join({{self_type}}.table){ var( {{self_type}}.table, "{{foreign_key}}" ) == var( {{relation_type}}.table, {{relation_type}}.__pkey__ ) }
      end

      # :nodoc:
      def self.__relation_key_table_{{method_name}}__ : Tuple(String, String)
        {
          {{relation_type}}.table.to_s,
          {{relation_type}}.__pkey__.to_s
        }
      end

      __on_init__ do
        {{self_type}}::RELATION_FILTERS["{{method_name}}"] = -> (x : Clear::SQL::SelectBuilder) { __relation_filter_{{method_name}}__(x) }
      end

      # The method {{method_name}} is a `belongs_to` relation
      #   to {{relation_type}}
      def {{method_name}} : {{ relation_type }}{{ nilable ? "?".id : "".id }}
        if cached = @_cached_{{method_name}}
          cached
        elsif @cache.try &.active? "{{method_name}}"
          cache = @cache.not_nil!

          model = @_cached_{{method_name}} = cache.hit("{{method_name}}",
            self.{{foreign_key}}_column.to_sql_value,
            {{relation_type}}
          ).first?

          {% if !nilable %} raise Clear::SQL::RecordNotFoundError.new if model.nil? {% end %}

          model
        else
          fkey = self.{{foreign_key}}_column.value(nil)

          {% if !nilable %}
            raise Clear::SQL::RecordNotFoundError.new if fkey.nil?
          {% else %}
            return nil if fkey.nil?
          {% end %}

          @_cached_{{method_name}} =
            {{relation_type}}.query
              .where{ var({{relation_type}}.table, {{relation_type}}.__pkey__) == fkey }
              .{{ !nilable ? "first!".id : "first".id }}
        end
      end

      {% if nilable %}
        def {{method_name}}! : {{relation_type}}
          model = self.{{method_name}}
          raise Clear::SQL::RecordNotFoundError.new if model.nil?
          model.not_nil!
        end # /  *!
      {% end %}

      def {{method_name}}=(model : {{ relation_type }}{{ nilable ? "?".id : "".id }})
        if model && model.try &.persisted?
          raise "`#{model.__pkey_column__.name}` must be fetchable when assigning to a `belongs_to` relation." unless model.__pkey_column__.defined?
          @{{foreign_key}}_column.value = model.__pkey__
        else
          {% if nilable %}
            @_cached_{{method_name}} = nil
            @{{foreign_key}}_column.value = nil
          {% end %}
        end

        @_cached_{{method_name}} = model
      end

      # :nodoc:
      # save the belongs_to model first if needed
      def _bt_save_{{method_name}}
        c = @_cached_{{method_name}}

        {% unless nilable %}
          add_error("{{method_name}}", "must be present") if c.nil? && self.{{foreign_key}}_column.value(nil).nil?
        {% end %}

        return if c.nil?

        unless c.persisted?
          if c.save
            @{{foreign_key}}_column.reset_convert(c.__pkey__)
          else
            add_error("{{method_name}}", c.print_errors)
          end
        else # relation model has been persisted after assigned to current model
          self.{{foreign_key}} = c.__pkey__
        end

      end # / _bt_save_*

      __on_init__ do
        {{self_type}}.before(:validate) do |mdl|
          mdl.as(self)._bt_save_{{method_name}}
        end
      end

      class Collection
        def with_{{method_name}}(fetch_columns = false, &block : {{relation_type}}::Collection -> ) : self
          before_query do
            sub_query = self.dup.clear_select.select("#{ item_class.table }.{{foreign_key.id}}")

            cached_qry = {{relation_type}}.query.where{ var({{relation_type}}.table, {{relation_type}}.__pkey__ ).in?(sub_query) }

            block.call(cached_qry)

            cache_name = {{"#{method_name}"}}
            @cache.active cache_name

            cached_qry.each(fetch_columns: fetch_columns) do |mdl|
              @cache.set(cache_name, mdl.__pkey__, [mdl])
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

end
