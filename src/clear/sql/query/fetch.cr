module Clear::SQL::Query::Fetch
  # :no_doc:
  protected def fetch_result_set(h : Hash(String, ::Clear::SQL::Any), rs, &block) : Bool
    return false unless rs.move_next

    loop do
      rs.each_column do |col|
        h[col] = rs.read
      end

      yield(h)

      break unless rs.move_next
    end

    true
  ensure
    rs.close
  end

  # Fetch the data using CURSOR.
  # This will prevent Clear to load all the data from the database into memory.
  # This is useful if you need to retrieve and update a large dataset.
  def fetch_with_cursor(count = 1_000, &block : Hash(String, ::Clear::SQL::Any) -> Void)
    trigger_before_query

    Clear::SQL.transaction do |cnx|
      cursor_name = "__cursor_#{Time.now.to_unix ^ (rand * 0xfffffff).to_i}__"

      cursor_declaration = "DECLARE #{cursor_name} CURSOR FOR #{to_sql}"

      Clear::SQL.log_query(cursor_declaration) { cnx.exec(cursor_declaration) }

      h = {} of String => ::Clear::SQL::Any

      we_loop = true

      while we_loop
        fetch_query = "FETCH #{count} FROM #{cursor_name}"

        rs = Clear::SQL.log_query(fetch_query) { cnx.query(fetch_query) }

        o = Array(Hash(String, ::Clear::SQL::Any)).new(initial_capacity: count)

        we_loop = fetch_result_set(h, rs) { |x| o << x.dup }

        o.each { |hash| yield(hash) }
      end
    end
  end

  # Helpers to fetch a SELECT with only one row and one column return.
  def scalar(type : T.class) forall T
    trigger_before_query

    sql = to_sql

    Clear::SQL.log_query sql do
      Clear::SQL::ConnectionPool.with_connection(connection_name, &.scalar(sql)).as(T)
    end
  end

  # Return the first line of the query as Hash(String, ::Clear::SQL::Any)
  def first
    limit(1).fetch(fetch_all: true) { |x| return x }
  end

  # Return an array with all the rows fetched.
  def to_a : Array(Hash(String, ::Clear::SQL::Any))
    trigger_before_query

    h = {} of String => ::Clear::SQL::Any

    sql = self.to_sql

    rs = Clear::SQL.log_query(sql) { Clear::SQL::ConnectionPool.with_connection(connection_name, &.query(sql)) }

    o = [] of Hash(String, ::Clear::SQL::Any)
    fetch_result_set(h, rs) { |x| o << x.dup }

    o
  end

  # Fetch the result set row per row
  # `fetch_all` optional parameter is helpful in transactional environment, so it stores
  # the result and close the resultset before starting to call yield over the data
  # preventing creation of a new connection if you need to call SQL into the
  # yielded block.
  #
  # ```crystal
  # # This is wrong: The connection is still busy retrieving the users:
  # Clear::SQL.select.from("users").fetch do |u|
  #   Clear::SQL.select.from("posts").where { u["id"] == posts.id }
  # end
  #
  # # Instead, use `fetch_all`
  # # Clear will store the value of the result set in memory
  # # before calling the block, and the connection is now ready to handle
  # # another query.
  # Clear::SQL.select.from("users").fetch(fetch_all:true) do |u|
  #   Clear::SQL.select.from("posts").where { u["id"] == posts.id }
  # end
  # ```
  def fetch(fetch_all = false, &block : Hash(String, ::Clear::SQL::Any) -> Void)
    trigger_before_query

    h = {} of String => ::Clear::SQL::Any

    sql = self.to_sql

    rs = Clear::SQL.log_query(sql) { Clear::SQL::ConnectionPool.with_connection(connection_name, &.query(sql)) }

    if fetch_all
      o = [] of Hash(String, ::Clear::SQL::Any)
      fetch_result_set(h, rs) { |x| o << x.dup }
      o.each { |x| yield(x) }
    else
      fetch_result_set(h, rs) { |x| yield(x) }
    end
  end
end
