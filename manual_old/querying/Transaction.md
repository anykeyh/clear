## Transaction

Clear offer simple transaction system. The methods are `Clear::SQL.transaction` and `Clear::SQL.rollback`.

During transaction, if any errors occurs or you manually call `Clear::SQL.rollback`, Clear will throw a `ROLLBACK`.

Note than `Clear::SQL.rollback` will not raise any errors, but the code after the rollback will never be executed.

```crystal
Clear::SQL.transaction do
  ## Do something

  Clear::SQL.rollback if something_wrong_happeneds
end
```

You can check whether you're in transaction at a specific moment by calling `Clear::SQL.in_transaction?`


## Savepoints



Transactions cannot be nested. This code will do exactly the same:

```crystal
Clear::SQL.transaction do
  Clear::SQL.rollback
  do_something
end

Clear::SQL.transaction do
  Clear::SQL.transaction do
    Clear::SQL.rollback
  end

  do_something
end
```
In both case, `do_something` will never be called.

That's where savepoint comes in:

```crystal
Clear::SQL.with_savepoint do
  Clear::SQL.rollback
  do_something
end

Clear::SQL.with_savepoint do
  Clear::SQL.with_savepoint do
    Clear::SQL.rollback
  end

  do_something
end
```

In this case, the second example will call `do_something`.

Savepoints can be nested and live into a transaction. Use them wisely !