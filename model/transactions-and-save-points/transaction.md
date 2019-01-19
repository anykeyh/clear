# Transaction & Savepoints

Transaction are safeguard to ensure than a list of operation on a database are only permanent if they can all succeed as atomic action.

In Clear, the usage of transaction is simple:

```ruby
Clear::SQL.transaction do
    yacine.withdraw(100)
    mary.deposit(100)
end
```

In the example above, if one of the method fail, the whole transaction block will be reverted to initial state.

### Rollback

You can manually rollback a transaction if something went wrong:

```ruby
Clear::SQL.transaction do
    yacine.withdraw(100)
    Clear::SQL.rollback if mary.is_suspicious?
    mary.deposit(100)
end
```

In this case, the block will be returned, nothing will be committed in the database and no error will be thrown

### Nested transaction

Nested transaction are not working, but save points are used for that. Let's take an example:

```ruby
Clear::SQL.transaction do
    puts "I do something"
    Clear::SQL.transaction do
        puts "I do another thing"
        Clear::SQL.rollback
        puts "This should not print"
    end
    puts "Eventually, I do something else"
end
```

In this case, the output will be:

```text
# BEGIN
I do something
I do another thing
# ROLLBACK
```

Since **nested transaction are not permitted**, rollback will rollback the top-most transaction. Any nested transaction block will perform SQL-wise, only the block content will be executed.

### Savepoints

For nested transaction, you may want to use save points:

```ruby
Clear::SQL.with_savepoint do
    puts "I do something"
    Clear::SQL.with_savepoint do
        puts "I do another thing"
        Clear::SQL.rollback
        puts "This should not print"
    end
    puts "Eventually, I do something else"
end
```

In this case, the output will be:

```text
# BEGIN
# SAVEPOINT xxx1
I do something
# SAVEPOINT xxx2
I do another thing
# ROLLBACK TO SAVEPOINT xxx2
Eventually, I do something else
# RELEASE SAVEPOINT xxx1
# COMMIT
```

As you can see, save points are backed by a transaction block; rollback inside a save point block will rollback the block only and not all the transaction. Any unhandled exception will still rollback the full transaction.

