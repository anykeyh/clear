# Aggregation

Each collection have simple access to aggregation functions.

### MIN, MAX, AVG and SUM

By default, `min`, `max`, `avg`, `sum` and `count` are mapped:

```ruby
user_count = User.query.count

user_max_id = User.query.max("id", Int64)
user_min_id = User.query.min("id", Int64)

user_average_time = User.query.avg("time_connected", Float64)
```

### Custom aggregation method

You can call you own custom aggregation method using `agg` method:

```ruby
time_squared = User.query.agg("AVG(timesquared * timesquared)", Float64)
```

