Sometime you want to query additional columns which are not in your model, like foreign joined columns or computed columns.

In this case, you must use the `fetch_columns` parameter in your query and access through `[]` operator to the value of the field:

```crystal
  u = User.query.select({full_name: "first_name || ' ' || last_name"}).first!(fetch_columns: true)
  full_name = u["full_name"].as(String)
  puts full_name
```

Note: Performance is slightly impacted when the model is fetching the extra columns.