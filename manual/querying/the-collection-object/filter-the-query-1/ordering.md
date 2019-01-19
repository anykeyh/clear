# Ordering & Group by

Ordering of the collection can be made by using `order_by` method, while Group by is done via `group_by` :

```ruby
User.query.order_by(last_name: "ASC", first_name: "ASC").each do |hash|
    puts "#{usr.first_name} #{usr.last_name}"
end
```

You can clear the current ordering by using the chainable method `clear_order_bys`

