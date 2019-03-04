# Eager Loading – Resolving the N+1 query problem

N+1 query is a common anti-pattern which happens when you call a relation inside a collection of model. Let's take this example:

```ruby
Post.query.each do |post|
    puts "Post category: #{post.category.name}" 
end

# Output:
# SELECT * FROM posts;
# SELECT * FROM categories WHERE post_id = 1
# SELECT * FROM categories WHERE post_id = 2
# SELECT * FROM categories WHERE post_id = 3
# SELECT * FROM categories WHERE post_id = 4
# SELECT * FROM categories WHERE post_id = 5
# ....
```

The problem is that it's way faster to query once 100 models than to query 100 times one model.

To deal with that, Clear offers convenient methods called `with_[model]` which build the query and cache the related model. Let's try it:

```ruby
Post.query.with_category.each do |post|
    puts "Post category: #{post.category.name}" 
end

# Output:
# SELECT * FROM category WHERE post_id IN (SELECT id FROM posts);
# SELECT * FROM posts;
```

We just resolved our problem, and the ORM will call only two time the database !

## Deep inclusion

`with_[model]` helper allow you to pass a block, which can refine the related object. Therefore, it's easy to include far-related model like in this example:

```ruby
User.query.with_posts(&.with_category).each do |user|
    puts "User #{user.id}'s posts:"
    user.posts.each do |post|
      puts "Post category: #{post.category.name}"
    end
end
```

Since the `with_[model]` helper return a collection in the block, you may want to even more optimize your query:

```ruby
User.query.with_posts{ |p|  
  p.where(published: true).with_category{ |c| 
    c.select("name")
  } 
}.each do |user|
    puts "User #{user.id}'s published posts:"
    user.posts.each do |post|
      puts "Post category: #{post.category.name}"
    end
end

# Note: we encourage using &.xxx notation and scopes for the query above. 
# It would then be rewritten like this:
User.query.with_posts(&.published.with_category(&.select("name"))).each do |user|
    puts "User #{user.id}'s published posts:"
    user.posts.each do |post|
      puts "Post category: #{post.category.name}"
    end
end
```

