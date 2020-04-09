# Primary Keys

Clear needs your model to define a primary key column. By default, Clear can handle properly `int`, `bigint`, `string` and `uuid` primary keys.

{% hint style="warning" %}
As time of writing this manual, compound primary keys are not handled properly.
{% endhint %}

## `primary_key` helper

Clear offers a built-in `primary_key` helper which will define your primary key without hassle:

```ruby
class Product
  include Clear::Model

  self.table = "products"

  primary_key name: "product_id", type: :uuid
end
```

* `name` is the name of your column in your table. \(Default: `id`\)
* `type` is the type of the column in your table. Set to \(Default: `bigserial`\).
* By default, types can be of type `bigserial`, `serial`, `int`, `bigint`, `text` and `uuid`.

Note than primary\_key directive in the model class is just a fast way of writing:

```ruby
column id : Int64, primary: true, presence: false
```

The primary key name is ID, of type bigint and it won't check the presence on save because it has default value

{% hint style="info" %}
In case of `uuid`, Clear will generate a new `uuid` at every new object creation before inserting it into the database.
{% endhint %}

