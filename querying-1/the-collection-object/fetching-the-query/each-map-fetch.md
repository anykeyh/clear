# Each and Fetch

Collection inherits from [`Enumerable(T)`](https://crystal-lang.org/api/latest/Enumerable.html) therefore it allows all the methods defined by the module. When calling enumeration via `each` or `map`or any other methods defined in `Enumerable(T)`,  the collection is resolved and SQL request is triggered.

### Collection\(T\)\#each

Return the list of models returned by the request:

```ruby
Post.query.where(user_id: 1).each do |posts|
    # Do something with the posts
end
```

### Collection\(T\)\#fetch

Fetch stands for iterating through hash instead of model. While offering less features \(as we do not connect a model to the data\), it offers best performances, as no extra-allocations are made:

```ruby
Post.query.where(user_id: 1).fetch do |posts|
    puts "#{post["id"]} - #{post["name"]}"
end
```

