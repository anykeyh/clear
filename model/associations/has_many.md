# has\_many

Has many represents one of the counter part of [belongs to](belongs_to.md) relation. It assumes the current model is referenced by a collection of another model.

Let's see the example used in the chapter [`belongs_to`](belongs_to.md):

```sql
CREATE TABLE categories (
    id bigserial NOT NULL PRIMARY KEY, 
    name text NOT NULL
)

CREATE TABLE posts (
    id bigserial NOT NULL PRIMARY KEY,
    name text NOT NULL,
    content text,
    category_id bigint NOT NULL
)
```

```ruby
class Post
  include Clear::Model
  
  with_serial_pkey
  
  column name : String
  column content : String?
  
  belongs_to category : Category
end

class Category
  with_serial_pkey
  
  column name : String
  
  has_many posts : Post
end
```

Here, we said a category has many posts. The posts can be accessed through the method `posts` which return a `Collection`:

```ruby
c = Category.query.find!{name == "Technology"} # Retrieve the category named Technology

c.posts.each do |post|
    puts "Post name: #{post.name}"
end
```

Note: The relation can be refined after fetching:

```ruby
# Fetch only the posts which starts by a digit: 
c.posts.where{name =~ /^[0-9]/i}.each do |post|
    puts "Post name: #{post.name}"
end
```

### Customizing the relation

Clear uses naming convention to infer the name of the foreign key. You may want to override this behavior by adding some parameters:

```ruby
has_many relation_name : RelationType, 
    foreign_key: "column_name", own_key: "column_name", no_cache: true|false
```

| Argument | Description | Default value |
| :---: | :--- | :---: |
| `foreign_key` | The foreign key which is inside the relative model | `[underscore_model_name]_id` |
| `own_key` | The key against what the relation is tested, primary key by default | `self.class.pkey` |
| `no_cache` | Never cache the relation \(note: planned feature\) | `false` |

### Adding to relation

An object can be added into the relation collection using `<<` operator:

```ruby
c.posts << Post.new({name: "A good post"})
```

In this case, the post is saved during the add operation.

