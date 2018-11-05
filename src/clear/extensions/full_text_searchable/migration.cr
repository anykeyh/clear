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
#   Post.create!({title: "You won't believe: She raises her poney like as star!", content: "She's col because poney are cool"})
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
struct Clear::Migration::FullTextSearchableOperation < Clear::Migration::Operation
  module Priority
    VERY_IMPORTANT = 'A'
    IMPORTANT      = 'B'
    NORMAL         = 'C'
    LOW            = 'D'
  end

  getter table : String
  getter trigger_name : String
  getter function_name : String
  getter catalog : String
  getter dest_field : String

  getter src_fields : Array({String, Char})

  def initialize(@table, @src_fields, @catalog = "pg_catalog.english",
                 trigger_name = nil, function_name = nil,
                 @dest_field = "full_text_vector")
    raise "Source fields cannot be empty" if @src_fields.empty?

    @table = table

    @trigger_name = trigger_name || "tsv_update_#{table}"
    @function_name = function_name || "tsv_trigger_#{table}"
  end

  private def ensure_priority!(field_priority : Char)
    unless field_priority >= 'A' && field_priority <= 'D'
      raise "Priority level for tsvector range from 'A' (higher) to 'D' (lower)"
    end
  end

  private def print_concat_rules(use_new = true)
    src_fields.map do |(field_name, field_priority)|
      ensure_priority!(field_priority)

      "setweight(to_tsvector(#{Clear::Expression[catalog]}, coalesce(#{use_new && "new." || ""}#{field_name}, ''))," +
        " #{Clear::Expression[field_priority]})"
    end.join(" || ")
  end

  private def print_trigger : Array(String)
    op = "new.#{dest_field} := #{print_concat_rules};"

    cr_fn = <<-SQL
      CREATE OR REPLACE FUNCTION #{function_name}() RETURNS trigger AS $$
      begin
        #{op}
        return new;
      end
      $$ LANGUAGE plpgsql;
    SQL

    cr_tr = <<-SQL
      CREATE TRIGGER #{trigger_name} BEFORE INSERT OR UPDATE
         ON #{table} FOR EACH ROW EXECUTE PROCEDURE #{function_name}();
      SQL

    return [cr_fn, cr_tr]
  end

  private def print_udpate_current_data
    op = print_concat_rules(use_new: false)

    return [Clear::SQL.update(table)
      .set({"#{dest_field}" => Clear::Expression.unsafe(op)}).to_sql]
  end

  private def print_delete_trigger
    return ["DROP FUNCTION #{function_name}()", "DROP TRIGGER #{trigger_name}"]
  end

  def up
    print_trigger + print_udpate_current_data
  end

  def down
    print_delete_trigger
  end
end

module Clear::Migration::FullTextSearchableHelpers
  # Add a `tsvector` field to a table.
  # Create column, index and trigger.
  def add_full_text_searchable(table, on : Array(Tuple(String, Char)),
                               column_name = "full_text_vector", catalog = "pg_catalog.english",
                               trigger_name = nil, function_name = nil)
    add_column(table, column_name, "tsvector")
    create_index(table, column_name, using: "gin")
    migration.add_operation(
      Clear::Migration::FullTextSearchableOperation.new(table,
        on, catalog, trigger_name, function_name, column_name)
    )
  end
end

module Clear::Migration::FullTextSearchableTableHelpers
  def full_text_searchable(on : Array(Tuple(String, Char)),
                           column_name = "full_text_vector", catalog = "pg_catalog.english",
                           trigger_name = nil, function_name = nil)
    tsvector(column_name, index: "gin")

    migration.add_operation(Clear::Migration::FullTextSearchableOperation.new(self.name,
      on, catalog, trigger_name, function_name, column_name))
  end

  def full_text_searchable(on : String, column_name = "full_text_vector",
                           catalog = "pg_catalog.english",
                           trigger_name = nil, function_name = nil)
    full_text_searchable([{on, 'C'}], column_name, catalog, trigger_name, function_name)
  end

  def full_text_searchable(on : Array(String), column_name = "full_text_vector",
                           catalog = "pg_catalog.english",
                           trigger_name = nil, function_name = nil)
    raise "cannot implement tsv_searchable because empty array was given" if on.empty?

    fields = on.map { |name| {name, 'C'} }

    full_text_searchable(fields, column_name, catalog, trigger_name, function_name)
  end
end
