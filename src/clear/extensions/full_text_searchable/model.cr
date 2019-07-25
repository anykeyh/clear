require "./tsvector"

# Full text search plugin offers full integration with `tsvector` capabilities of
# Postgresql.
#
# It allows you to query models through the text content of one or multiple fields.
#
# ### The blog example
#
# Let's assume we have a blog and want to implement full text search over title and content:
#
# ```crystal
# create_table "posts" do |t|
#   t.string "title", nullable: false
#   t.string "content", nullable: false
#
#   t.full_text_searchable on: [{"title", 'A'}, {"content", 'C'}]
# end
# ```
#
# This migration will create a 3rd column named `full_text_vector` of type `tsvector`,
# a gin index, a trigger and a function to update automatically this column.
#
# Over the `on` keyword, `'{"title", 'A'}'` means it allows search of the content of "title", with level of priority (weight) "A", which tells postgres than title content is more meaningful than the article content itself.
#
# Now, let's build some models:
#
# ```crystal
#
#   model Post
#     include Clear::Model
#     #...
#
#     full_text_searchable
#   end
#
#   Post.create!({title: "About poney", content: "Poney are cool"})
#   Post.create!({title: "About dog and cat", content: "Cat and dog are cool. But not as much as poney"})
#   Post.create!({title: "You won't believe: She raises her poney like as star!", content: "She's cool because poney are cool"})
# ```
#
# Search is now easily done
# ```crystal
# Post.query.search("poney") # Return all the articles !
# ```
#
# Obviously, search call can be chained:
#
# ```crystal
# user = User.find! { email == "some_email@example.com" }
# Post.query.from_user(user).search("orm")
# ```
#
# ### Additional parameters
#
# #### `catalog`
#
# Select the catalog to use to build the tsquery. By default, `pg_catalog.english` is used.
#
# ```crystal
# # in your migration:
# t.full_text_searchable on: [{"title", 'A'}, {"content", 'C'}], catalog: "pg_catalog.french"
#
# # in your model
# full_text_searchable catalog: "pg_catalog.french"
# ```
#
# Note: For now, Clear doesn't offers dynamic selection of catalog (for let's say multi-lang service).
# If your app need this feature, do not hesitate to open an issue.
#
# #### `trigger_name`, `function_name`
#
# In migration, you can change the name generated for the trigger and the function, using theses two keys.
#
# #### `dest_field`
#
# The field created in the database, which will contains your ts vector. Default is `full_text_vector`.
#
# ```crystal
# # in your migration
# t.full_text_searchable on: [{"title", 'A'}, {"content", 'C'}], dest_field: "tsv"
#
# # in your model
# full_text_searchable "tsv"
# ```
module Clear::Model::FullTextSearchable
  # Set this model as searchable using tsvector
  macro full_text_searchable(through = "full_text_vector", catalog = "pg_catalog.english", scope_name = "search")
    column( {{through.id}} : Clear::TSVector, presence: false)

    scope "{{scope_name.id}}" do |str|
      table = self.item_class.table
      where{ op( var(table, "{{through.id}}"), to_tsquery({{catalog}},
        Clear::Model::FullTextSearchable.to_tsq(str)), "@@") }
    end
  end

  # :nodoc:
  # Split a chain written by a user
  # The problem comes from the usage of `'` in languages like French
  # which can easily break a tsvector query
  #
  # ameba:disable Metrics/CyclomaticComplexity (Is parser)
  private def self.split_to_exp(text)
    last_char : Char? = nil
    quote_char : Char? = nil
    modifier : Symbol? = nil

    currtoken = [] of Char
    arr_tokens = [] of {Symbol?, String}

    text.chars.each do |c|
      case c
      when '\''
        if quote_char.nil?
          if last_char.to_s =~ /[a-z0-9]/i # Avoid french word e.g. "l'avion"
            currtoken << c
          else
            quote_char = '\''
          end
        elsif quote_char == '\''
          arr_tokens << {modifier, currtoken.join}
          currtoken.clear
          modifier = nil
          quote_char = nil
        else
          currtoken << c
        end
      when ' '
        if quote_char.nil?
          if currtoken.any?
            arr_tokens << {modifier, currtoken.join}
            currtoken.clear
          end
          modifier = nil
        else
          currtoken << c
        end
      when '"'
        if (quote_char.nil?)
          quote_char = '"'
        elsif quote_char == '"'
          arr_tokens << {modifier, currtoken.join}
          currtoken.clear
          modifier = nil
          quote_char = nil
        else
          currtoken << c
        end
      when '-'
        if currtoken.empty? && quote_char.nil? # When first char of the token == `-`
          modifier = :-
        else
          currtoken << c
        end
      else
        currtoken << c
      end

      last_char = c
    end

    if currtoken.any?
      arr_tokens << {modifier, currtoken.join}
    end

    arr_tokens
  end

  # Parse client side text and generate string ready to be ingested by PG's `to_tsquery`.
  #
  # Author note: pg `to_tsquery` is awesome but can easily fail to parse.
  #   `search` method use then a wrapper text_to_search used to ensure than
  #   request is understood and produce ALWAYS legal string for `to_tsquery`
  # This is a good helper then to use with the input of your end-users !
  #
  # However, this helper can be improved, as it doesn't use all the features
  # of tsvector (parentesis, OR operator etc...)
  def self.to_tsq(text)
    text = text.gsub(/\+/, " ")
    tokens = split_to_exp(text)

    tokens.map do |(modifier, value)|
      if modifier == :-
        "!" + Clear::Expression[value]
      else
        Clear::Expression[value]
      end
    end.join(" & ")
  end
end
