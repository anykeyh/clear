# Window and CTE

## Common Table Expressions \(CTE\)

PostgreSQL offers writing of [Common Table Expressions \(CTE\)](https://www.postgresql.org/docs/current/queries-with.html) . Common Table Expressions are useful to define temporary SQL query used in a bigger query.

For this example, let's assume we want to count the new user creation per day during the month of September. One way would be to Group by `EXTRACT('day' FROM created_at)` , but days without new user will return not rows, where we want it to return zero.

In this case, using joins onto a generated series of day is the way to go. CTE makes it very simple to write and manage:

```ruby
dates_in_september = Clear::SQL.select({
    day_start: "generate_series(date '2018-09-01', date '2018-09-30', '1 day'::interval)", 
    day_end: "generate_series(date '2018-09-01', date '2018-09-30', '1 day'::interval) + '1 day'::interval";
})

Clear::SQL.select({
    count: "COUNT(users.*)",
    day: "dates.day_start"
})
.with_cte(dates: dates_in_septembers)
.from("dates")
.left_joins(User.table){ (users.created_at >= day_start) & (users.created_at < day_end) }
.group_by("dates.day_start")
.order_by("dates.day_start")
.fetch do |hash|
    puts "users created the #{hash["day"]}: #{hash["count"]}"
end
```

{% hint style="info" %}
Since all model collections are SQL query, you can pass collection as parameter of `with_cte` block.
{% endhint %}

## Window

You can [pass window ](https://www.postgresql.org/docs/current/tutorial-window.html)using window method:

```ruby
Clear::SQL
    .select("sum(salary) OVER w", "avg(salary) OVER w")
    .from("empsalary")
    .window({w: "(PARTITION BY depname ORDER BY salary DESC)"})
```

