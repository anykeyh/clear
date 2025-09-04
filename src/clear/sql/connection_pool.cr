class Clear::SQL::ConnectionPool
  @@databases = {} of String => DB::Database

  @@fiber_connections = {} of {String, Fiber} => DB::Connection

  def self.init(uri, name)
    @@databases[name] = DB.open(uri)
  end

  # Retrieve a connection from the connection pool, or wait for it.
  # If the current Fiber already has a connection, the connection is returned;
  #   this strategy provides easy usage of multiple statement connection (like BEGIN/ROLLBACK features).
  def self.with_connection(target : String, &)
    fiber_target = {target, Fiber.current}

    database = @@databases.fetch(target) { raise Clear::ErrorMessages.uninitialized_db_connection(target) }

    cnx = @@fiber_connections[fiber_target]?

    if cnx
      yield cnx
    else
      database.using_connection do |new_connection|
        begin
          @@fiber_connections[fiber_target] = new_connection
          yield new_connection
        ensure
          @@fiber_connections.delete(fiber_target)
        end
      end
    end
  end
end
