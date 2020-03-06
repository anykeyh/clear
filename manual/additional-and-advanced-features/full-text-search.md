# Full Text Search

Full text search plugin offers full integration with `tsvector` capabilities of Postgresql.

It allows you to query models through the text content of one or multiple fields.

Let's assume we have a blog and want to implement full text search over title and content:

```ruby
  create_table "posts" do |t|
    t.column :title, :string, null: false
    t.column :content, :string, null: false

    t.full_text_searchable on: [{"title", 'A'}, {"content", 'C'}]
  end
```

This migration will create a 3rd column named `full_text_vector` of type `tsvector`, a gin index, a trigger and a function to update automatically this column.

Over the `on` keyword, `'{"title", 'A'}'` means it allows search of the content of "title", with level of priority \(weight\) "A", which tells postgres than title content is more meaningful than the article content itself.

Now, let's build some models:

```ruby
  class Post
    include Clear::Model
    #...

    full_text_searchable
  end

  Post.create!({title: "About poney", content: "Poney are cool"})
  Post.create!({title: "About dog and cat", content: "Cat and dog are cool. But not as much as poney"})
  Post.create!({title: "You won't believe: She raises her poney like as star!", content: "She's col because poney are cool"})
```

Search is now easily done

```ruby
  Post.query.search("poney") # Return all the articles !
```

Obviously, search call can be chained:

```ruby
  user = User.find!{ email == "some_email@example.com" }
  Post.query.from_user(user).search("orm")
```

## Additional parameters

**catalog**

Select the catalog to use to build the `tsquery`. By default, `pg_catalog.english` is used.

```ruby
# in your migration:
t.full_text_searchable on: [{"title", 'A'}, {"content", 'C'}], catalog: "pg_catalog.french"

# in your model
full_text_searchable catalog: "pg_catalog.french"
```

{% hint style="info" %}
For now, Clear doesn't offers dynamic selection of catalog \(for let's say multi-lang service\). If your app need this feature, do not hesitate to open an issue.
{% endhint %}

**trigger\_name, function\_name**

In migration, you can change the name generated for the trigger and the function, using theses two keys.

**dest\_field**

The field created in the database, which will contains your ts vector. Default is `full_text_vector`.

```ruby
#in your migration
t.full_text_searchable on: [{"title", 'A'}, {"content", 'C'}], dest_field: "tsv"

# in your model
full_text_searchable "tsv"
```

