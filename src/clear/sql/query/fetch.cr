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

    return true
  ensure
    rs.close
  end

  # Use a cursor to fetch the data
  def fetch_with_cursor(count = 1_000, &block : Hash(String, ::Clear::SQL::Any) -> Void)
    trigger_before_query

    Clear::SQL.transaction do
      cnx = Clear::SQL.connection(self.connection_name)
      cursor_name = "__cursor_#{Time.now.epoch ^ (rand * 0xfffffff).to_i}__"

      cursor_declaration = "DECLARE #{cursor_name} CURSOR FOR #{to_sql}"

      Clear::SQL.log_query(cursor_declaration) { cnx.exec(cursor_declaration) }

      h = {} of String => ::Clear::SQL::Any

      we_loop = true
      while we_loop
        fetch_query = "FETCH #{count} FROM #{cursor_name}"

        rs = uninitialized PG::ResultSet

        Clear::SQL.log_query(fetch_query) { rs = cnx.query(fetch_query) }

        o = Array(Hash(String, ::Clear::SQL::Any)).new(initial_capacity: count)

        we_loop = fetch_result_set(h, rs) { |x| o << x.dup }

        o.each { |hash| yield(hash) }
      end
    end
  end

  # Get a scalar (EG count)
  #
  def scalar(type : T.class) forall T
    trigger_before_query

    Clear::SQL.log_query to_sql do
      Clear::SQL.connection(self.connection_name).scalar(to_sql).as(T)
    end
  end

  def first
    limit(1).fetch(fetch_all: true) { |x| return x }
  end

  def to_a : Array(Hash(String, ::Clear::SQL::Any))
    trigger_before_query

    h = {} of String => ::Clear::SQL::Any

    to_sql = self.to_sql

    rs = uninitialized PG::ResultSet
    Clear::SQL.log_query(to_sql) { rs = Clear::SQL.connection(self.connection_name).query(to_sql) }

    o = [] of Hash(String, ::Clear::SQL::Any)
    fetch_result_set(h, rs) { |x| o << x.dup }

    o
  end

  # Fetch the result set row per row
  # `fetch_all` is helpful in transactional environment, so it stores
  # the result and close the resultset before strating to dispatch the data
  # preventing creation of a new connection if you need to call SQL into the
  # yielded block.
  def fetch(fetch_all = false, &block : Hash(String, ::Clear::SQL::Any) -> Void)
    trigger_before_query

    h = {} of String => ::Clear::SQL::Any

    to_sql = self.to_sql

    rs = uninitialized PG::ResultSet

    Clear::SQL.log_query(to_sql) { rs = Clear::SQL.connection(connection_name).query(to_sql) }

    if fetch_all
      o = [] of Hash(String, ::Clear::SQL::Any)
      fetch_result_set(h, rs) { |x| o << x.dup }
      o.each { |x| yield(x) }
    else
      fetch_result_set(h, rs) { |x| yield(x) }
    end
  end
end
