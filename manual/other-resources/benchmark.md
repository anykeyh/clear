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

Here is a simple benchmark comparing the different layers of Clear and how they impact the performance, over a 100k row very simple table:

```text
With Model: With attributes and cursor    7.4  (135.09ms) (± 6.44%)  116409530 B/op   5.64× slower
               With Model: With cursor   8.61  (116.08ms) (± 2.82%)   97209247 B/op   4.84× slower
           With Model: With attributes  13.78  ( 72.59ms) (± 3.61%)   83101520 B/op   3.03× slower
          With Model: Simple load 100k  16.41  ( 60.94ms) (± 3.22%)   63901872 B/op   2.54× slower
                    Hash from SQL only  30.21  (  33.1ms) (± 5.18%)   22354496 B/op   1.38× slower
        Using: Model::Collection#pluck  41.74  ( 23.96ms) (± 8.35%)   25337128 B/op        fastest
```

## Against the competition

While being a bit outdated, a benchmark of the competition [has been done here](https://github.com/jwoertink/crystal_orm_test).

Clear stands in the middle of the crowd, being slightly slower than some other ORM over `select` methods.

More noticeably, Clear performs 5 to 8x faster than Ruby's ActiveRecord !

