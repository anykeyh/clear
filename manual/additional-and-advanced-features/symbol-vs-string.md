# Symbol vs String

In most query building methods, we allow symbols and strings to be given as parameter. 

While not being always true, when using `Symbol`, Clear will try to escape the word using double quote during the request building, while `String` will be printed out as it.

```ruby
# SELECT * FROM "users" INNER JOIN "orders" on "order_id" == "orders"."id"
User.query.join(:orders){order_id == orders.id }

# SELECT * FROM "users" INNER JOIN orders on "order_id" == "orders"."id"
User.query.join("orders"){order_id == orders.id }
```

In case of wrong behavior, do not hesitate to [fill an issue here](https://github.com/anykeyh/clear/issues).

