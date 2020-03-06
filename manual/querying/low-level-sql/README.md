# Writing low-level SQL

Under the hood, Clear offers a performant SQL query builder for `SELECT`, `INSERT` and `DELETE` clauses:

 Under the hood, the

```ruby
Clear::SQL.select.from("users").execute # SELECT * FROM users;
```



