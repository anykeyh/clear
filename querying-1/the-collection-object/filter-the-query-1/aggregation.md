# Aggregation

Clears offers simple access to aggregation functions.

By default, `min`, `max`, `avg` and `count` are mapped: 

```ruby
user_count = User.query.count

user_max_id = User.query.max("id", Int64)
user_min_id = User.query.min("id", Int64)

user_average_time = User.query.avg("time_connected", Float64)
```



