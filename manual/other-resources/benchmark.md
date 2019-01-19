# Benchmark

## How fast is Clear?

## Initial bootstrapping

Clear magic is built on compile time. Therefore, the impact on loading time is very limited. Clear can be used for example into web function \(lambda function, google cloud function\) application without any problem.

The only overhead is the connection to the database; Clear allocate by default 5 connections to PostgreSQL. In the case of mono-fiber web-function projects, you may want to reduce the connection pool to 1 only:

```ruby
Clear::SQL.init("postgres://postgres@localhost/example_db", connection_pool_size: 1)
```

Another good performance improvement would be to connect through [PGBouncer](https://pgbouncer.github.io/) instead of directly to the database.

## Query and fetching benchmark

Here is a simple benchmark comparing the different layers of Clear and how they impact the performance, over a 100k row simple table:

| Method | Total Time | Speed |
| :--- | :--- | :--- |
| `User.query.each` | \( 83.03ms\) \(± 3.87%\) | 2.28× slower |
| `User.query.each_with_cursor` | \( 121.0ms\) \(± 1.25%\) | 3.32× slower |
| `User.query.each(fetch_columns: true)` | \( 97.12ms\) \(± 4.07%\) | 2.67× slower |
| `User.query.each_with_cursor(fetch_columns: true)` | \(132.52ms\) \(± 2.39%\) | 3.64× slower |
| `User.query.fetch` | \( 36.42ms\) \(± 5.05%\) | fastest |

## Against the competition

While being a bit outdated, a benchmark of the competition [has been done here](https://github.com/jwoertink/crystal_orm_test).

Clear stands in the middle of the crowd, being slightly slower than some other ORM over `select` methods.

More noticeably, Clear performs 5 to 8x faster than Ruby's ActiveRecord !

