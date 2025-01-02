# Connection pool

Clear uses connection pooling to allow multiple transactions to run in parallel over multiple fibers.

By default, each connection is fetched from the connection pool for each fibers. Let's see this example:

```ruby
begin
  Clear::SQL.execute("CREATE TABLE tests (id serial PRIMARY KEY)")

  spawn do
    # Clear automatically create a connection nº1 
    Clear::SQL.transaction do
      Clear::SQL.insert("tests", {id: 1}).execute
      sleep 0.2.seconds # Wait and do not commit the transaction for now
    end
  end

  @@count = -1

  # Spawn a new fiber
  spawn do
    sleep 0.1.seconds # Wait a bit, to ensure than the first connection is inside a transaction
    # execute in connection nº2
    @@count = Clear::SQL.select.from("tests").count
  end

  sleep 0.3.seconds # Let the 2 fiber time to finish...

  # The count is zero, because: it has been setup by the second fiber, which
  # called AFTER the insert but BEFORE the commit on the connection nº1
  @@count.should eq 0 

  # Now the transaction of connection nº1 is over, count should be 1
  count = Clear::SQL.select.from("tests").count
  count.should eq 1
ensure
  Clear::SQL.execute("DROP TABLE tests;")
end
```

Each call to SQL is using a new connection, from the free connection pool; if a transaction is in progress, each call will use the same connection during the whole transaction.

{% hint style="warning" %}
If all the connections are busy, the fiber will wait indefinitely until a new connection is freed.
{% endhint %}

{% hint style="danger" %}
There is currently no way to force a fiber to use the same connection has another fiber. This may be improved in the future.
{% endhint %}

