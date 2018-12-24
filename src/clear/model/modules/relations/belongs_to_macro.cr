# :nodoc:
module Clear::Model::Relations::BelongsToMacro
  macro generate(self_type, method_name, relation_type, foreign_key, primary, no_cache, key_type)
    {% foreign_key = foreign_key || method_name.stringify.underscore + "_id" %}

    column {{foreign_key.id}} : {{key_type}}, primary: {{primary}}
    getter _cached_{{method_name}} : {{relation_type}}?

    # The method {{method_name}} is a `belongs_to` relation
    #   to {{relation_type}}
    def {{method_name}} : {{relation_type}}?
      if @cached_{{method_name}}
        @cached_{{method_name}}
      else
        cache = @cache

        if cache && cache.active? "{{method_name}}"
          @cached_{{method_name}} = cache.hit("{{method_name}}", self.{{foreign_key.id}}, {{relation_type}}).first?
        else
          @cached_{{method_name}} = {{relation_type}}.query.where{ raw({{relation_type}}.pkey) == self.{{foreign_key.id}} }.first
        end
      end
    end # / *

    def {{method_name}}! : {{relation_type}}
      {{method_name}}.not_nil!
    end # /  *!

    def {{method_name}}=(x : {{relation_type}}?)
      if x.persisted?
        raise "#{x.pkey_column.name} must be defined when assigning a belongs_to relation." unless x.pkey_column.defined?
        @{{foreign_key.id}}_column.value = x.pkey
      end

      @cached_{{method_name}} = x
    end # / *=

    # :nodoc:
    # save the belongs_to model first if needed
    def _bt_save_{{method_name}}
      c = @cached_{{method_name}}
      return if c.nil?

      unless c.persisted?
        if c.save
          @{{foreign_key.id}}_column.value = c.pkey
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
          sub_query = self.dup.clear_select.select("#{{{self_type}}.table}.{{foreign_key.id}}")

          cached_qry = {{relation_type}}.query.where{ raw({{relation_type}}.pkey).in?(sub_query) }

          block.call(cached_qry)

          @cache.active "{{method_name}}"

          cached_qry.each(fetch_columns: fetch_columns) do |mdl|
            @cache.set("{{method_name}}", mdl.pkey, [mdl])
          end
        end

        self
      end # / with_*

      def with_{{method_name}}(fetch_columns = false) : self
        with_{{method_name}}(fetch_columns){}
        self
      end # / with_*

    end # / Collection

  end # / macro

end