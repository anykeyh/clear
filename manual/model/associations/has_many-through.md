# has\_many through

Has many through represents a relation where both side can relate to multiple models.

Basically, in SQL this can be performed by using a middle-table which store foreign key of both of the classes.

## Usage Example

For example, let's assume we have a table `posts` and a table `tags` which are loosely connected: a post can have multiple `tags` at once, while a tag can references multiple posts. In this example, we will need a middle-table which will be named `post_tags` :

```sql
CREATE TABLE tags (
    id bigserial NOT NULL PRIMARY KEY, 
    name text NOT NULL
);

CREATE UNIQUE INDEX tags_name ON tags (name);

CREATE TABLE posts (
    id bigserial NOT NULL PRIMARY KEY,
    name text NOT NULL,
    content text
);

CREATE TABLE post_tags (
    tag_id bigint NOT NULL, 
    post_id bigint NOT NULL, 
    FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE, 
    FOREIGN KEY (post_id) REFERENCES posts (id) ON DELETE CASCADE
);
```

You may notice usage of FOREIGN KEY constraints over post\_tags. Clear doesn't provide any feature for cascading deletion, and relay exclusively on PostgreSQL.

Now, let's define our models:

```ruby
class Post
  include Clear::Model

  primary_key

  column name : String
  column content : String?

  has_many tags : Tag, through: "post_tags"
end

class Tag
  include Clear::Model

  primary_key

  column name : String

  has_many tags : Post, through: "post_tags"
end
```

And thats all ! Basically, in this case, we may not want to create a model `PostTag` as the table exists only to make the link between the two models.

Addition and deletion is provided in elegant way even without model:

{% code title="add\_to\_post.cr" %}
```ruby
p = Post.new({name: "My new post"})
p.save!
# Add the tag Technology to the post
p.tags << Tag.query.find_or_create({name: "Technology"}){}
```
{% endcode %}

p has to be saved in database before linking the tag.

{% code title="delete\_tag.cr" %}
```ruby
p = Post.query.first!

tags = p.tags
tags.unlink( tags.where(name: "Technology").first! )
```
{% endcode %}

## Middle-table model

Optionally, we can define our middle-table model. In this case, you should use the model as through argument :

```ruby
class Post
  include Clear::Model

  class Tag
    include Clear::Model

    belongs_to post : Post
    belongs_to tag : Tag

    self.table = "post_tags"
  end

  primary_key

  column name : String
  column content : String?

  has_many tags : Tag, through: Post::Tag
end

class Tag
  include Clear::Model

  primary_key

  column name : String

  has_many tags : Post, through: Post::Tag
end
```

**Note:** The model `Post::Tag` don't have primary key which can lead to issues with Clear. [Feel free to leave issues to the community here.](https://github.com/anykeyh/clear/issues)

