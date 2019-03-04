# The collection object

Each model offers an object called `ModelName::Collection`. This `Collection` object offers a way to query the database and perform operations on large groups of model.

To instantiate a new `Collection`, you can simply call the method `query` over the model class:

```ruby
users = User.query
```

## Collection and SELECT query

When instantiated, the collection is Crystal's coexistence of the a SELECT query:

```sql
SELECT * FROM users
```

Therefore, calling to\_a over the Collection will fetch all the models from the database to your crystal code:

```sql
array_of_users = User.query.to_a
```

Collection will really perform SQL request only on resolution time, when calling `each` or `to_a` for example.

## Mutability

Collection are mutable objects, and many of the methods will change the state of the collection:

```ruby
collection = User.query # SELECT * FROM users;
collection.select("id") # SELECT id FROM users;
collection.select("id") # SELECT id, id FROM users;
```

Therefore, you may want to use `Collection#dup` to duplicate the current state of the collection.

Collection can be filtered and refined to query exactly what you want. Actually, they are refined version of `SQL::SelectBuilder` object [described in Low-level SQL chapter](../low-level-sql/).

