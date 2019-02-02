class Clear::SQL::ConnectionPool
  @@connections = {} of String => Channel(DB::Database)

  @@fiber_connections = {} of {String, Fiber} => { DB::Database, Int32 }

  def self.init(uri, name, pool_size)
    raise "Connection pool size must be position" unless pool_size > 0
    channel = @@connections[name] = Channel(DB::Database).new(capacity: pool_size)
    pool_size.times{ channel.send DB.open(uri) }
  end

  # Retrieve a connection from the connection pool, or wait for it.
  # If the current Fiber already has a connection, the connection is returned;
  #   this strategy provides easy usage of multiple statement connection (like BEGIN/ROLLBACK features).
  def self.with_connection(target : String, &block)
    fiber_target = {target, Fiber.current}

    channel = @@connections.fetch(target){ raise Clear::ErrorMessages.uninitialized_db_connection(target) }
    db, call_count = @@fiber_connections.fetch(fiber_target){ { channel.receive, 0} }

    begin
      @@fiber_connections[fiber_target] = {db, call_count+1}
      yield(db)
    ensure
      db, call_count = @@fiber_connections[fiber_target]

      if call_count == 1
        @@fiber_connections.delete(fiber_target)
        channel.send db
      else
        @@fiber_connections[fiber_target] = {db, call_count - 1}
      end
    end
  end

end