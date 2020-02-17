# :nodoc:
module Clear::Model::Relations::BelongsToMacro

  macro __filter_relation_belongs_to__(self_class, relation, final, query)
    {% begin %}
      {%
        foreign_key = (relation[:foreign_key] || "#{method_name.stringify.underscore}_id").id
        relation_type = relation[:type].id
      %}

      {{query}}.inner_join{ var( {{self_class}}.table, "{{foreign_key}}" ) == var( {{relation_type}}.table, {{relation_type}}.pkey ) }

      {% debug(false) %}
    {% end %}
  end

  macro generate(self_type, relation)
    {% begin %}
      {%
        foreign_key = (relation[:foreign_key] || "#{method_name.stringify.underscore}_id").id
        foreign_key_type = relation[:foreign_key_type].id
        method_name = relation[:name].id
        relation_type = relation[:type].id

        presence = relation[:presence]
        primary = relation[:primary]

        nilable = relation[:nilable]
      %}

      __define_association_cache__({{method_name}}, {{relation_type}})
      column {{foreign_key}} : {{foreign_key_type}}{{ nilable ? "?".id : "".id }}, primary: {{primary}}, presence: false

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
              .where{ var({{relation_type}}.table, {{relation_type}}.pkey) == fkey }
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
        if model.try &.persisted?
          raise "`#{model.pkey_column.name}` must be fetchable when assigning to a `belongs_to` relation." unless model.pkey_column.defined?
          @{{foreign_key}}_column.value = model.pkey
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
            @{{foreign_key}}_column.value = c.pkey
          else
            add_error("{{method_name}}", c.print_errors)
          end
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

            cached_qry = {{relation_type}}.query.where{ var({{relation_type}}.table, {{relation_type}}.pkey ).in?(sub_query) }

            block.call(cached_qry)

            cache_name = {{"#{method_name}"}}
            @cache.active cache_name

            cached_qry.each(fetch_columns: fetch_columns) do |mdl|
              @cache.set(cache_name, mdl.pkey, [mdl])
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