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
      # :nodoc:
      RELATIONS = {} of Nil => Nil
    end
  end

  # The method `has_one` declare a relation 1 to [0,1]
  # where the current model primary key is stored in the foreign table.
  # `primary_key` method (default: `self#pkey`) and `foreign_key` method
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
  macro has_one(name, foreign_key = nil, primary_key = nil, no_cache = false, polymorphic = false, foreign_key_type = nil)
    {%
      foreign_key = foreign_key.id if foreign_key.is_a?(SymbolLiteral) || foreign_key.is_a?(StringLiteral)
      primary_key = primary_key.id if primary_key.is_a?(SymbolLiteral) || primary_key.is_a?(StringLiteral)

      RELATIONS[name.var.id] = {
        relation_type: :has_one,

        type: name.type,

        foreign_key: foreign_key,
        primary_key: primary_key,
        no_cache: no_cache
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
  #   class User
  #     include Clear::Model
  #     #...
  #     has_many posts : Post, foreign_key: "author_id"
  #  end
  # ```
  macro has_many(name, through = nil, foreign_key = nil, own_key = nil, primary_key = nil, no_cache = false, polymorphic = false, foreign_key_type = nil)
    {%
      if through != nil

        through = through.id if through.is_a?(SymbolLiteral) || through.is_a?(StringLiteral)

        own_key     = own_key.id if own_key.is_a?(SymbolLiteral) || own_key.is_a?(StringLiteral)
        foreign_key = foreign_key.id if foreign_key.is_a?(SymbolLiteral) || foreign_key.is_a?(StringLiteral)
        foreign_key_type = foreign_key_type.id if foreign_key_type.is_a?(SymbolLiteral) || foreign_key_type.is_a?(StringLiteral)

        RELATIONS[name.var.id] = {
          relation_type: :has_many_through,
          type: name.type,

          through: through,
          own_key: own_key,

          foreign_key: foreign_key,
          foreign_key_type: foreign_key_type,

          polymorphic: polymorphic
        }

      else
        foreign_key = foreign_key.id if foreign_key.is_a?(SymbolLiteral) || foreign_key.is_a?(StringLiteral)
        primary_key = primary_key.id if primary_key.is_a?(SymbolLiteral) || primary_key.is_a?(StringLiteral)
        foreign_key_type = foreign_key_type.id if foreign_key_type.is_a?(SymbolLiteral) || foreign_key_type.is_a?(StringLiteral)

        RELATIONS[name.var.id] = {
          relation_type: :has_many,
          type: name.type,

          foreign_key: foreign_key,
          primary_key: primary_key,
          foreign_key_type: foreign_key_type,

          no_cache: no_cache,
          polymorphic: polymorphic
        }
      end
    %}
  end


  # ```
  # class Model
  #   include Clear::Model
  #   belongs_to user : User, foreign_key: "the_user_id"
  #
  # ```
  macro belongs_to(name, foreign_key = nil, no_cache = false, primary = false, key_type = Int64?)
    {%
    foreign_key = foreign_key.id if foreign_key.is_a?(SymbolLiteral) || foreign_key.is_a?(StringLiteral)

    RELATIONS[name.var.id] = {
      relation_type: :belongs_to,

      type: name.type,

      foreign_key: foreign_key,
      primary: primary,
      no_cache: no_cache,
      key_type: key_type
    }
    %}
  end

  # :nodoc:
  # Generate the relations by calling the macro
  macro __generate_relations__
    {% begin %}
    {% for name, settings in RELATIONS %}
      {% if settings[:relation_type] == :belongs_to %}
        Relations::BelongsToMacro.generate({{@type}}, {{name}}, {{settings[:type]}}, {{settings[:foreign_key]}},
          {{settings[:primary]}}, {{settings[:no_cache]}}, {{settings[:key_type]}})
      {% elsif settings[:relation_type] == :has_many %}
        Relations::HasManyMacro.generate({{@type}}, {{name}}, {{settings[:type]}}, {{settings[:foreign_key]}},
          {{settings[:primary_key]}})
      {% elsif settings[:relation_type] == :has_many_through %}
        Relations::HasManyThroughMacro.generate({{@type}}, {{name}}, {{settings[:type]}}, {{settings[:through]}},
          {{settings[:own_key]}}, {{settings[:foreign_key]}})
      {% elsif settings[:relation_type] ==  :has_one %}
        Relations::HasOneMacro.generate({{@type}}, {{name}}, {{settings[:type]}}, {{settings[:foreign_key]}},
          {{settings[:primary_key]}})
      {% else %}
        {% raise "I don't know this relation: #{settings[:relation_type]}" %}
      {% end %}
    {% end %}
    {% end %}
  end


end
