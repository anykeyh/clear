Often you will need to connect to two or more database, due to legacy code.

Clear offers multi-connections possibility, and your model can live in a specific database.

If not multiple connection are set, clear use `default` connection as living place for the models.

## Setup the multiple connections

```crystal
  Clear::SQL.init("default", "postgres://[USER]:[PASSWORD]@[HOST]/[DATABASE]")
  Clear::SQL.init("secondary", "postgres://[USER]:[PASSWORD]@[HOST]/[DATABASE]")
```

You can also use hash notation:

```crystal
  Clear::SQL.init(
    "default" => "postgres://[USER]:[PASSWORD]@[HOST]/[DATABASE]",
    "legacy" => "postgres://[USER]:[PASSWORD]@[HOST]/[DATABASE]"
  )
```

## Setup model connection

You can then just change the class property `connection` in your model definition:

```crystal
class OldUser
  self.table = "users"
  self.connection = "legacy"
end
```

## Additional notes

- Migrations always occurs to the database under `default` connection
- Models between different connections should not share relations. We cannot guarantee the behavior in case you connect models between differents databases.