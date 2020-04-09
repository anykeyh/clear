# Handling multi-connection

Often you will need to connect to two or more database, due to legacy code.

Clear offers multi-connections possibility, and your model can live in a specific database.

If not multiple connection are set, clear use `default` connection as living place for the models.

### Setup the multiple connections

```ruby
  Clear::SQL.init("default", "postgres://[USER]:[PASSWORD]@[HOST]/[DATABASE]")
  Clear::SQL.add_connection("secondary", "postgres://[USER]:[PASSWORD]@[HOST]/[DATABASE]")
```

You can also use hash notation:

```ruby
  Clear::SQL.init(
    "default" => "postgres://[USER]:[PASSWORD]@[HOST]/[DATABASE]",
    "legacy" => "postgres://[USER]:[PASSWORD]@[HOST]/[DATABASE]"
  )
```

### Setup model connection

You can then just change the class property `connection` in your model definition:

```ruby
class OldUser
  self.table = "users"
  self.connection = "legacy"
end
```

{% hint style="info" %}
Migrations always occurs to the database under `default` connection
{% endhint %}

{% hint style="danger" %}
Models between different connections should not share relations. We cannot guarantee the behavior in case you connect models between differents databases.
{% endhint %}

### Other connection with SQL Builder

In low-level API, you can call `use_connection` to force a request to be called on a specific collection:

```ruby
Clear::SQL.select.use_connection("legacy").from("users").fetch{ |u| ... }
```

