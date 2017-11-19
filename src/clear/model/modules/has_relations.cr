# ```
# class Model
#   include Clear::Model
#
#   has_many posts : Post, [ foreign_key: Model.underscore_name + "_id", no_cache : false]
#
#   has_one passport : Passport
#   has_many posts
# ```
module Clear::Model::HasRelations
  # The method `has_one` declare a relation 1 to [0,1]
  # where the current model primary key is stored in the foreign table.
  # `primary_key` method (default: `self#pkey`) and `foreign_key` method
  # (default: table_name in singular, plus "_id" appended)
  # can be redefined
  #
  # Examples:
  # ```
  # model Passport
  #   column id : Int32, primary : true
  #   has_one user : User It assumes the table `users` have a field `passport_id`
  # end
  #
  # model Passport
  #   column id : Int32, primary : true
  #   has_one owner : User # It assumes the table `users` have a field `passport_id`
  # end
  # ```
  macro has_one(name, foreign_key = nil, primary_key = nil)
    {% relation_type = name.type %}
    {% method_name = name.var.id %}

    # `{{method_name}}` is of type `has_one` relation to {{relation_type}}
    def {{method_name}} : {{relation_type}}?
      %primary_key = {{(primary_key || "pkey").id}}
      %foreign_key =  {{foreign_key}} || ( self.class.table.to_s.singularize + "_id" )

      {{relation_type}}.query.where{ raw(%foreign_key) == %primary_key }.first
    end

    def {{method_name}}! : {{relation_type}}
      {{method_name}}.not_nil!
    end

    # Addition of the method for eager loading and N+1 avoidance.
    class Collection
      # Eager load the relation {{method_name}}.
      # Use it to avoid N+1 queries.
      def with_{{method_name}}(fetch_columns = false) : self
        before_query do
          %primary_key = {{(primary_key || "#{relation_type}.pkey").id}}
          %foreign_key =  {{foreign_key}} || ( {{@type}}.table.to_s.singularize + "_id" )

          #SELECT * FROM foreign WHERE foreign_key IN ( SELECT primary_key FROM users )
          sub_query = self.dup.clear_select.select("#{%primary_key}")

          {{relation_type}}.query.where{ raw(%foreign_key).in?(sub_query) }.each(fetch_columns: true) do |mdl|
            puts "Set {{@type}}.{{method_name}}.#{mdl.pkey}"

            Clear::Model::Cache.instance.set(
              "{{@type}}.{{method_name}}", mdl.attributes[%foreign_key], [mdl]
            )
          end
        end

        self
      end
    end
  end

  # has_many through \o/
  macro has_many(name, through, own_key = nil, foreign_key = nil)
    {% relation_type = name.type %}
    {% method_name = name.var.id %}

    def {{method_name}} : {{relation_type}}::Collection
      %final_table = {{relation_type}}.table
      %final_pkey = {{relation_type}}.pkey
      %through_table = {{through}}.table
      %through_key = {{foreign_key}} || {{relation_type}}.table.to_s.singularize + "_id"
      %own_key = {{own_key}} || {{@type}}.table.to_s.singularize + "_id"

      cache = @cache

      qry = {{relation_type}}.query.join(%through_table){
          var("#{%through_table}.#{%through_key}") == var("#{%final_table}.#{%final_pkey}")
        }.where{
          var("#{%through_table}.#{%own_key}") == self.id
        }.distinct.select("#{%final_table}.*")


      if cache && cache.active?("{{method_name}}")
        arr = cache.hit("{{method_name}}", self.pkey, {{relation_type}})
        qry.with_cached_result(arr)
      end

      qry
    end

    # Addition of the method for eager loading and N+1 avoidance.
    class Collection
      # Eager load the relation {{method_name}}.
      # Use it to avoid N+1 queries.
      def with_{{method_name}}(&block : {{relation_type}}::Collection -> ) : self
        before_query do
          %final_table = {{relation_type}}.table
          %final_pkey = {{relation_type}}.pkey
          %through_table = {{through}}.table
          %through_key = {{foreign_key}} || {{relation_type}}.table.to_s.singularize + "_id"
          %own_key = {{own_key}} || {{@type}}.table.to_s.singularize + "_id"
          self_type = {{@type}}

          @cache.active "{{method_name}}"

          sub_query = self.dup.clear_select.select(self_type.pkey)

          qry = {{relation_type}}.query.join(%through_table){
            var("#{%through_table}.#{%through_key}") == var("#{%final_table}.#{%final_pkey}")
          }.where{
            var("#{%through_table}.#{%own_key}").in?(sub_query)
          }.distinct.select( "#{%final_table}.*",
            "#{%through_table}.#{%own_key} AS __own_id"
          )

          block.call(qry)

          h = {} of Clear::SQL::Any => Array({{relation_type}})

          qry.each(fetch_columns: true) do |mdl|
            unless h[mdl.attributes["__own_id"]]?
              h[mdl.attributes["__own_id"]] = [] of {{relation_type}}
            end

            h[mdl.attributes["__own_id"]] << mdl
          end

          h.each do |key, value|
            @cache.set("{{method_name}}", key, value)
          end
        end

        self
      end

      def with_{{method_name}}
        with_{{method_name}}{}
      end

    end

  end

  # has many
  macro has_many(name, foreign_key = nil, primary_key = nil)
    {% relation_type = name.type %}
    {% method_name = name.var.id %}

    # The method {{method_name}} is a `has_many` relation
    #   to {{relation_type}}
    def {{method_name}} : {{relation_type}}::Collection
      %primary_key = {{(primary_key || "pkey").id}}
      %foreign_key =  {{foreign_key}} || ( self.class.table.to_s.singularize + "_id" )


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
      #end
    end

    # Addition of the method for eager loading and N+1 avoidance.
    class Collection
      # Eager load the relation {{method_name}}.
      # Use it to avoid N+1 queries.
      def with_{{method_name}}(fetch_columns = false, &block : {{relation_type}}::Collection -> ) : self
        before_query do
          %primary_key = {{(primary_key || "#{relation_type}.pkey").id}}
          %foreign_key =  {{foreign_key}} || ( {{@type}}.table.to_s.singularize + "_id" )

          #SELECT * FROM foreign WHERE foreign_key IN ( SELECT primary_key FROM users )
          sub_query = self.dup.clear_select.select("#{%primary_key}")

          qry = {{relation_type}}.query.where{ raw(%foreign_key).in?(sub_query) }
          block.call(qry)

          @cache.active "{{method_name}}"

          qry.each(fetch_columns: fetch_columns) do |mdl|
            @cache.set(
              "{{method_name}}", mdl.pkey, [mdl]
            )
          end
        end

        self
      end

      def with_{{method_name}}(fetch_columns = false)
        with_{{method_name}}(fetch_columns){|q|} #empty block
      end
    end
  end

  # ```
  # class Model
  #   include Clear::Model
  #   belongs_to user : User, foreign_key: "the_user_id"
  #
  # ```
  macro belongs_to(name, foreign_key = nil, no_cache = false, primary = false, key_type = Int32?)
    {% relation_type = name.type %}
    {% method_name = name.var.id %}
    {% foreign_key = foreign_key || relation_type.stringify.underscore + "_id" %}

    column {{foreign_key.id}} : {{key_type}}, primary: {{primary}}

    # The method {{method_name}} is a `belongs_to` relation
    #   to {{relation_type}}
    def {{method_name}} : {{relation_type}}?

      cache = @cache

      if cache && cache.active? "{{method_name}}"
        cache.hit("{{method_name}}", self.{{foreign_key.id}}, {{relation_type}}).first?
      else
        {{relation_type}}.query.where{ raw({{relation_type}}.pkey) == self.{{foreign_key.id}} }.first
      end
    end

    def {{method_name}}! : {{relation_type}}
      {{method_name}}.not_nil!
    end

    def {{method_name}}=(x : {{relation_type}}?)
      @{{foreign_key.id}}_field.value = x.pkey
    end

    # Adding the eager loading
    class Collection
      def with_{{method_name}}(fetch_columns = false, &block : {{relation_type}}::Collection -> ) : self
        before_query do
          sub_query = self.dup.clear_select.select({{foreign_key.id.stringify}})

          cached_qry = {{relation_type}}.query.where{ raw({{relation_type}}.pkey).in?(sub_query) }

          block.call(cached_qry)

          @cache.active "{{method_name}}"

          cached_qry.each(fetch_columns: fetch_columns) do |mdl|
            @cache.set("{{method_name}}", mdl.pkey, [mdl])
          end
        end

        self
      end

      def with_{{method_name}}(fetch_columns = false) : self
        with_{{method_name}}(fetch_columns){}
        self
      end

    end

  end
end
