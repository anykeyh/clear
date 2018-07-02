Full text search plugin offers full integration with `tsvector` capabilities of
Postgresql.

It allows you to query models through the text content of one or multiple fields.

### The blog example

Let's assume we have a blog and want to implement full text search over title and content:

```crystal
  create_table "posts" do |t|
    t.string "title", nullable: false
    t.string "content", nullable: false

    t.full_text_searchable on: [{"title", 'A'}, {"content", 'C'}]
  end
```

This migration will create a 3rd column named `full_text_vector` of type `tsvector`,
a gin index, a trigger and a function to update automatically this column.

Over the `on` keyword, '{"title", 'A'}' means it allows search of the content of "title", with level of priority (weight) "A", which tell postgres than title content is more meaningful than the article content itself.

Now, let's build some models:

```crystal
  Post.create!({title: "About poney", content: "Poney are cool"})
  Post.create!({title: "About dog and cat", content: "Cat and dog are cool. But not as much as poney"})
  Post.create!({title: "You won't believe: She raises her poney like as star!", content: "She's col because poney are cool"})
```

Search is now easily done
```
  Post.query.search("poney") # Return all the articles !
```