# Primary Keys

Clear needs your model to define a primary key column. By default, Clear can handle properly `int`, `bigint`, `string` and `uuid` primary keys.

{% hint style="warning" %}
As time of writing this manual, compound primary keys are not handled properly.
{% endhint %}

## `with_serial_pkey` helper

Clear offers a built-in `with_serial_pkey` helper which will define your primary key without hassle:

```ruby
class Product
  include Clear::Model

  self.table = "products"

  with_serial_pkey name: "product_id", type: :uuid
end
```

* `name` is the name of your column in your table. Set to `id` by default
* `type` is the type of the column in your table. Set to `bigserial` by default.
  * type can be of type `bigserial`, `serial`, `text` and `uuid`. 

{% hint style="info" %}
In case of `uuid`, Clear will generate a new `uuid` at every new object creation before inserting it into the database.
{% endhint %}

