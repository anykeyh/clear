Model definition is made by adding the `Clear::Model` mixin in your class.

## Simple Model

```crystal
class MyModel
  include Clear::Model

  column my_column : String
end
```

We just created a new model, linked to your database, mapping the column `my_column` of type String (`text` in postgres).

Now, you can play with your model:

```crystal
  row = MyModel.new # create an empty row
  row.my_column = "This is a content"
  row.save! # insert the new row in the database !
```

By convention, the table name will follow an underscore, plural version of your model: `my_models`.
A model into a module will prepend the module name before, so `Logistic::MyModel` will check for `logistic_my_models` in your database.
You can force a specific table name using:

```crystal
class MyModel
  include Clear::Model
  self.table = "another_table_name"
end
```

## Presence validation

Unlike many ORM around, Clear carry about non-nullable pattern in crystal. Meaning `column my_column : String` assume than a call to `row.my_column` will return a String.

But it exists case where the column is not yet initialized:
- When the object is built with constructor without providing the value (See above).
- When an object is semi-fetched through the database query. This is useful to ignore some large fields non-interesting in the body of the current operation.

For example, this code will compile:

```crystal
  row = MyModel.new # create an empty row
  puts row.my_column
```

However, it will throw a runtime exception `You cannot access to the field 'my_column' because it never has been initialized`

Same way, trying to save the object will raise an error:

```crystal
  row.save # Will return false
  pp row.errors # Will tell you than `my_column` presence is mandatory.
```

Thanks to expressiveness of the Crystal language, we can handle presence validation by simply using the `Nilable` type in crystal:

```crystal
class MyModel
  include Clear::Model

  column my_column : String? # Now, the column can be NULL or text in postgres.
end
```

This time, the code above will works; in case of no value, my_column will be `nil` by default.

## Querying your code

Whenever you want to fetch data from your database, you must create a new collection query:

`MyModel.query #Will setup a vanilla 'SELECT * FROM my_models'`

Queries are fetchable using `each`:

```crystal
MyModel.query.each do |model|
  # Do something with your model here.
end
```

## Refining your query

A collection query offers a lot of functionalities. You can read the [API](https://anykeyh.github.io/clear/Clear/Model/CollectionBase.html) for more informations.

## Column type

By default, Clear map theses columns types:

- `String` => `text`
- `Numbers` (any from 8 to 64 bits, float, double, big number, big float) => `int, large int etc... (depends of your choice)`
- `Bool` => `text or bool`
- `Time` => `timestamp without timezone or text`
- `JSON::Any` => `json and jsonb`
- `Nilable` => `NULL` (treated as special !)

_NOTE_: The `crystal-pg` gems map also some structures like GIS coordinates, but their implementation is not tested in Clear. Use them at your own risk. Tell me if it's working 😉

If you need to map special structure, see [Mapping Your Data](Mapping) guides for more informations.

## Primary key

Primary key is essential for (relational mapping)[RelationMapping]. Currently Clear support only one column primary key, even if it's planned to change this is the future.

A model without primary key can work in sort of degraded mode, throwing error in case of using some methods on them:
- `collection#first` will be throwing error if no `order_by` has been setup

To setup a primary key, you can add the modifier `primary: true` to the column:

```crystal
class MyModel
  include Clear::Model

  column id : Int32, primary: true, presence: false
  column my_column : String?
end
```

Note the flag `presence: false` added to the column. This tells Clear than presence checking on save is not mandatory. Usually this happens if you setup a default value in postgres. In the case of our primary key `id`, we use a serial auto-increment default value.
Therefore, saving the model without primary key will works. The id will be fetched after insertion:

```crystal
m = MyModel
m.save!
m.id # Now the id value is setup.
```

## Helpers

Clear provides various built-in helpers to facilitate your life:

### Timestamps

```crystal
class MyModel
  include Clear::Model
  timestamps #Will map the two columns 'created_at' and 'updated_at', and map some hooks to update their values.
end
```

Theses fields are automatically updated whenever you call `save` methods, and works as Rails ActiveRecord.

### With Serial Pkey

```crystal
class MyModel
  include Clear::Model
  primary_key "my_primary_key"
end
```

Basically rewrite `column id : UInt64, primary: true, presence: false`

Argument is optional (default = id)