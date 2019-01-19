# Cursored fetching

When resolving the query, all the models are stored in memory before being processed.

This behavior can overload the memory in case of large dataset of models. To prevent this, clear offers the methods `each_with_cursors`and `fetch_with_cursors` :

```ruby
User.query.each_with_cursor do |usr|
    #...
end
```

The block retrieved on each call can be tweaked using `batch` optional parameter \(default: 1000 models retrieved per call\) :

```ruby
User.query.each_with_cursor(100) do |usr|
    #...
end
```

