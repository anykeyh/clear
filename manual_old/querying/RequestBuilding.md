Clear offers low level SQL fetching.

This allow you to call complex SQL queries outside of models (e.g. Statistics), and also improve usually the code speed by 2 to 3 times compared to model.

Since Clear doesn't implement yet batch update / deletion through model collection, the only way to do it is using the SQL builder.

Note than SQL Select Builder is the base class of Collections, so all the methods are usable in a model context. You won't feel like learning another syntax !

## Build a query

SQL builder offers 4 methods:

- `Clear::SQL.select(*fields = "*")`
- `Clear::SQL.insert(table, *args)`
- `Clear::SQL.delete(table)`
- `Clear::SQL.update(table)`

### Example of queries

#### Select query

[API documentation](https://anykeyh.github.io/clear/Clear/SQL/SelectBuilder.html)

```crystal
Clear::SQL.select.from(:users)
                 .join(:role_users) { var("role_users.user_id") == users.id }
                 .join(:roles) { var("role_users.role_id") == var("roles.id") }
                 .where({role: ["admin", "superadmin"]})
                 .order_by({priority: :desc, name: :asc})
                 .limit(50)
                 .offset(50)
```

Fetching the result:

```crystal
  query.fetch do |hash|
    ... #Do something with the hash.
  end
```


#### Insert query

[API documentation](https://anykeyh.github.io/clear/Clear/SQL/InsertQuery.html)

```crystal
  Clear::SQL.insert("users", {a: "c", b: 12}).execute
```

Ohhh... Sub query are available to.

```crystal
  Clear::SQL.insert("users", Clear::SQL.select.from("admin_users")).execute
```

And if your table has all default or `NULL` values

```crystal
Clear::SQL.insert("users").execute # INSERT INTO users DEFAULT VALUES;
```

#### Delete query

[API documentation](https://anykeyh.github.io/clear/Clear/SQL/DeleteQuery.html)

```crystal
Clear::SQL.delete("table").where{ created_at < 5.days.ago }.execute #Prune the database !
```

Know you start to know the deal, subquery are working etc...

```crystal
Clear::SQL.delete("table").where{ id.in?(super_complex_select_query) }.execute
```

#### Update query

[API documentation](https://anykeyh.github.io/clear/Clear/SQL/UpdateQuery.html)

```crystal
Clear::SQL.update("table").set({x: 0}).where{ x < 0 }.execute #UPDATE table SET x = 0 WHERE x < 0
```

## Executing arbitrary SQL

- You can use `Clear::SQL.execute(sql)` to execute arbitrary SQL code.
- You can use `Clear::Expression[value]` to sanitize your values

```crystal
  Clear::SQL.execute <<-SQL
    INSERT INTO table (a,b) VALUES (#{Clear::Expression[x]), #{Clear::Expression[y]})
  SQL
```