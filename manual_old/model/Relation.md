Clear offers to map `belongs_to`, `has_one`, `has_many`, `has_many through:` relations.

## Belongs to

Belongs to relation is setup on the side where the foreign key is. For example, if a post belongs to a user, that's mean the post has a column connecting to the user (ex: `author_id`).

### Example

```crystal

class Post
  include Clear::Model

  belongs_to user : User, foreign_key: "author_id"
end
```

You can then call the user through post:

```
p = Post.query.first
p.user #Will fetch the user
```

By convention, the default value for `foreign_key` is `[model_name.underscore]_id`, for example `user_info_id` for the class UserInfo.

Optionally, you can force to use other names:

| param | |
|---|---|
| foreign_key | Name of the foreign key |
| primary | If the foreign_key is also the primary key of this table |
| key_type | The type used for the key. Default is Int64? |

By choice, `belongs_to` relation are always nilable. To use the object not nil, use `name!` instead of `name`:

```crystal
post.user! #< not nil !
```

## Has Many

Has Many and Has One are the relations where the model share its primary key into a foreign table. In our example above, we can assume than a User has many Post as author.

Basically, for each `belongs_to` declaration, you must have a `has_many` or `has_one` declaration on the other model.

While `has_many` relation returns a list of models, `has_one` returns only one model when called.

### Example

```crystal
class User
  include Clear::Model
  #...
  has_many posts : Post, foreign_key: "author_id"
end
```

In this case, we say "a user has many posts, which can be found comparing user.id with posts.author_id".

### Usage

The relation is a collection and can be refined:

```crystal
  # Fetch posts about technology:
  user.posts.where{ title.ilike("%technology%") }
```

You can build objects through the relation:

```crystal
  new_post = user.posts.build
  new_post.title = "..."
  new_post.save! #The foreign key author_id is already setup !
```

## Avoiding N+1 queries
The problem with the calling of a relation is it will trigger a query for each call. For example:

```crystal
 Post.query.map do |p|
    p.user!.name
 end
```

This will call a request for fetching the post, then a request for each call to user.
To avoid this, you can encache the relation:

```crystal
  Post.query.with_user.map do |p|
    p.user!.name
  end
```

Here, only two requests will be executed:

```sql
SELECT * FROM posts;
SELECT * FROM users WHERE id IN ( SELECT id FROM posts );
```

### Refining the association query

There's case where you want to query the association with some refining. But filter an association will disable the N+1 query caching. To avoid this, Clear offers a way to filter the association into the `with_*` method:

```crystal
# We want to list all the published posts of the users:
User.query.with_posts{ |p| p.where({published: true) }.each do |user|
  user.posts.each do |post|
    puts post.inspect
  end
end
```

Usage of scope makes it even more readable:

```crystal
User.query.with_posts(&.published).each do |user|
  #...
```

### Eager loading chaining 

You can then chain easily multiple associations:

```crystal
User.query.with_posts(&.published.with_category).each do |post|
  #...
```

At call to each, three requests will be called:

```sql
SELECT * FROM categories WHERE id IN ( SELECT category_id FROM posts WHERE user_id IN ( SELECT id FROM users ) )
SELECT * FROM posts WHERE user_id IN ( SELECT id FROM users )
SELECT * FROM users
```

Another cool thing is instead of Rails, the `IN` is using a subquery instead of an array of id. This avoid the back-and-forth between the app and the database, and the subqueries are repeated later on, Postgres server will then encache them making it fast like you never experienced before 👍.