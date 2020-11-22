require "./relations/*"

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
  macro included # In Clear::Model
    macro included # In RealModel
      include Clear::Model::Relations::BelongsToMacro
      include Clear::Model::Relations::HasOneMacro
      include Clear::Model::Relations::HasManyMacro
      include Clear::Model::Relations::HasManyThroughMacro

      RELATION_FILTERS = {} of String => (Clear::SQL::SelectBuilder -> )

      def self.__call_relation_filter__(name : String, query : Clear::SQL::SelectBuilder)
        cb = RELATION_FILTERS[name]?

        if !cb
          raise "Cannot find relation #{name} of #{self.name}. Candidates are: #{RELATION_FILTERS.keys.join("\n")}"
        end

        cb.call(query)
      end

      # :nodoc:
      RELATIONS = { } of String => {
        name: String,
        type: String,                       # Type of the Relation
        nilable: Bool,

        relation_type: Symbol,              # :has_many_through | :has_many | :belongs_to | :has_one

        foreign_key: String?,               # In case of :has_many or :belongs_to
        foreign_key_type: String?,          # Type of the foreign_key

        polymorphic: Bool,
        polymorphic_type_column: String?,   # The column used for polymorphism. Usually foreign_key

        through: String?,                   # In case of has_many through, which relation is used to pass through
        relation: String?,                        # In case of has_many through, the field used in the relation to pass through

        primary: Bool,                      # For belongs_to, whether the column is primary or not.
        presence: Bool,                     # For belongs_to, check or not the presence

        cache: Bool,                        # whether the model will cache the relation
      }
    end
  end

  # The method `has_one` declare a relation 1 to [0,1]
  # where the current model primary key is stored in the foreign table.
  # `primary_key` method (default: `self#__pkey__`) and `foreign_key` method
  # (default: table_name in singular, plus "_id" appended)
  # can be redefined
  #
  # Example:
  #
  # ```
  # model Passport
  #   column id : Int32, primary : true
  #   has_one user : User It assumes the table `users` have a column `passport_id`
  # end
  #
  # model Passport
  #   column id : Int32, primary : true
  #   has_one owner : User # It assumes the table `users` have a column `passport_id`
  # end
  # ```
  macro has_one(name, foreign_key = nil, foreign_key_type = Int64, cache = true, polymorphic = false, polymorphic_type_column = nil)
    {%
      foreign_key = "#{foreign_key.id}" if foreign_key
      foreign_key_type = "#{foreign_key_type.id}" if foreign_key_type
      polymorphic_type_column = "#{polymorphic_type_column.id}" if polymorphic_type_column

      if name.type.is_a?(Union) # Nilable?
        nilable = name.type.types.map { |x| "#{x.id}" }.includes?("Nil")
        type = name.type.types.first
      else
        type = name.type
        nilable = false
      end

      RELATIONS["#{name.var.id}"] = {
        name: "#{name.var.id}",
        type: type,

        relation_type: :has_one,
        nilable:       nilable,

        foreign_key:      foreign_key,
        foreign_key_type: foreign_key_type,

        polymorphic:             polymorphic,
        polymorphic_type_column: polymorphic_type_column,

        primary:  false,
        presence: true,

        through: nil,
        cache:   cache,
      }
    %}
  end

  # Has Many and Has One are the relations where the model share its primary key into a foreign table. In our example above, we can assume than a User has many Post as author.
  #
  # Basically, for each `belongs_to` declaration, you must have a `has_many` or `has_one` declaration on the other model.
  #
  # While `has_many` relation returns a list of models, `has_one` returns only one model when called.
  #
  # Example:
  #
  # ```crystal
  # class User
  #   include Clear::Model
  #   # ...
  #   has_many posts : Post, foreign_key: "author_id"
  # end
  # ```
  macro has_many(name, foreign_key = nil, foreign_key_type = Int64,
                 cache = true, polymorphic = false, relation = nil,
                 polymorphic_type_column = nil, through = nil)
    {%
      foreign_key = "#{foreign_key.id}" if foreign_key
      foreign_key_type = "#{foreign_key_type.id}" if foreign_key_type
      polymorphic_type_column = "#{polymorphic_type_column.id}" if polymorphic_type_column
      relation = "#{relation.id}" if relation
      through = "#{through.id}" if through

      RELATIONS["#{name.var.id}"] = {
        name: "#{name.var.id}",
        type: name.type,

        relation_type: through ? :has_many_through : :has_many,
        relation:      relation,

        foreign_key:      foreign_key,
        foreign_key_type: foreign_key_type,

        polymorphic:             polymorphic,
        polymorphic_type_column: polymorphic_type_column,

        primary:  false,
        presence: false,

        through: through,
        cache:   cache,
      }
    %}
  end

  # ```
  # class Model
  #   include Clear::Model
  #   belongs_to user : User, foreign_key: "the_user_id"
  #
  # ```
  macro belongs_to(name, foreign_key = nil, cache = true, primary = false,
                   foreign_key_type = Int64, polymorphic = false,
                   polymorphic_type_column = nil, presence = true)

    {%
      foreign_key = "#{foreign_key.id}" if foreign_key
      foreign_key_type = "#{foreign_key_type.id}" if foreign_key_type

      nilable = false

      if name.type.is_a?(Union) # Nilable?
        nilable = name.type.types.map { |x| "#{x.id}" }.includes?("Nil")
        type = name.type.types.first
      else
        type = name.type
        nilable = false
      end

      RELATIONS["#{name.var.id}"] = {
        name: "#{name.var.id}",
        type: type,

        relation_type: :belongs_to,
        nilable:       nilable,

        foreign_key:      foreign_key,
        foreign_key_type: foreign_key_type,

        polymorphic:             polymorphic,
        polymorphic_type_column: polymorphic_type_column,

        primary:  primary,
        presence: presence,

        through: nil,
        cache:   cache,
      }
    %}
  end

  # :nodoc:
  # helper to generate cache data for association
  macro __define_association_cache__(name, type)
    {% begin %}
      getter _cached_{{name}} : {{type}}?

      def invalidate_caches
        previous_def

        @_cached_{{name}} = nil
        self
      end
    {% end %}
  end

  # :nodoc:
  # Generate the relations by calling the macro
  macro __generate_relations__
    {% begin %}
      {% for name, settings in RELATIONS %}
        {% if settings[:relation_type] == :belongs_to %}
          Relations::BelongsToMacro.generate({{@type}}, {{settings}})
        {% elsif settings[:relation_type] == :has_many %}
          Relations::HasManyMacro.generate({{@type}}, {{settings}})
        {% elsif settings[:relation_type] == :has_many_through %}
          {%
            through_relation = RELATIONS["#{settings[:through].id}"]
            if through_relation == nil
              all_relations = RELATIONS.keys
              raise "[has_many #{name.id} through: ...]: Cannot find the relation `#{settings[:through].id}`" +
                    " in model #{@type}. Existing relations are: #{all_relations.join(", ").id}"
            end
          %}
          Relations::HasManyThroughMacro.generate({{@type}}, {{settings}}, {{ RELATIONS["#{settings[:through].id}"] }} )
        {% elsif settings[:relation_type] == :has_one %}
          Relations::HasOneMacro.generate({{@type}}, {{settings}})
        {% else %}
          {% raise "I don't know this relation type: #{settings[:relation_type]}" %}
        {% end %}
      {% end %}
    {% end %}
  end
end
