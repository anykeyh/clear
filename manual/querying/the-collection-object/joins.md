# Joins

In Clear, since every Collection is a SelectBuilder object, you can write very complex queries in a simple fashion. Let's see this example:

```ruby
# Get the posts of the users which have more than X posts:
def user_with_more_than_x_posts(post_count)
  User.query
    .select("users.id as id")
    .inner_joins("posts"){ posts.user_id == users.id }
    .group_by("users.id")
    .having{ raw("COUNT(*)") > post_count }
end

# Get the posts of the users with more than 10 posts:
Post.query.where{ user_id.in?(user_with_more_than_x_posts(10)) }
```

## Joins

Joins are built using `inner_join`, `left_join`, `right_join`, `cross_join` or simply `join` method. An optional block is requested for condition:

```ruby
# Retrieve users with supervisors
User.query.left_joins("users as u2"){ users.supervisor_id = u2.id }
```

Additionally, optional parameter `lateral` can be set to true to create a LATERAL JOIN.

