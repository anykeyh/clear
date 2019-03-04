Clear offers helpers to call aggregate functions over your models.

## Count

Count can be used over the query system:

```crystal
User.query.count
```

By default, count return a `Int64`, but you can select the type of output you are looking for:

```crystal
User.query.count(UInt32)
```

Count is working too with pagination:

```crystal
User.query.offset(15).limit(5).count # Will return SELECT COUNT(*) FROM (SELECT 1 FROM users OFFSET 15 LIMIT 5)
```

## MIN, MAX, AVG

Min, Max and Average are callable through the query system:

```crystal
  last_id = User.query.max(:id, UInt64)
```

## Customizable Aggregates

It's possible to call custom aggregate function like Median using `agg`:

```crystal
weighted_avg = User.query.agg( "SUM(performance_weight * performance_score) / SUM(performance_weight)", Float64 )
```