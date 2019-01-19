# Find, First, Last, Offset, Limit

You may want to fetch one model instead of a collection.

### Find

`Collection#find` allows to fetch a model based on an expression.

There's two flavors for `find` method: `find` and `find!` . The first one return a nilable type, which will be `nil` if not found, while the second return a model or throw an exception if not found. 

#### Example

```ruby
p = Product.query.find({id: 1234}) # Return Product?

p = Product.query.find!{ id == 1234 } # Return Product or throw an exception if not found.
```

### First / Last

First and last return the first and last row of a SELECT query. 

In the case of first, it will order by `$pkey ASC` if no `order_by` directive is found. In the case of last, it will invert the direction of the order directive of the query before performing the call.

Both limit the request to only 1 element and return the model instead of an enumeration of models.

```ruby
# SELECT * FROM products ORDER BY created_at ASC LIMIT 1
p = Product.query.order_by("created_at", "DESC").last!

# SELECT * FROM products ORDER BY created_at DESC LIMIT 1
p = Product.query.order_by("created_at", "DESC").first!
```

### Offset, Limit

Offset and limit provide a way to scope the request or do some pagination.

#### Offset

```ruby
Product.query.order_by("id").limit(5).offset(5)
```

The code above will fetch the model from position `5 .. 10` of the query.

It is possible to write the same behavior as above by using `[]` operator:

```ruby
products = Product.query.order_by("id")[5..10]
```

{% hint style="warning" %}
There's a difference of usage: Usage of `[]` operator will trigger the call to the query and return an Array of product, and not a Collection object anymore.
{% endhint %}

{% hint style="info" %}
You may use the `[]` operator with a number as parameter instead of range. In this case, it's equivalent to `offset(number).first!`. The `[]?` operator provides the `Collection#first` method and will return `nilable` reference.
{% endhint %}

