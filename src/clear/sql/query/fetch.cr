module Clear::SQL::Query::Fetch
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
  def fetch_with_cursor(count = 1000, &block : Hash(String, ::Clear::SQL::Any) -> Void)
    trigger_before_query

    Clear::SQL.connection.transaction do |tx|
      cnx = tx.connection
      cursor_name = "__cursor_#{Time.now.epoch ^ (rand * 0xfffffff).to_i}__"

      cursor_declaration = "DECLARE #{cursor_name} CURSOR FOR #{to_sql}"

      Clear::SQL.log_query(cursor_declaration) { cnx.exec(cursor_declaration) }

      n = count

      h = {} of String => ::Clear::SQL::Any

      we_loop = true
      while we_loop
        fetch_query = "FETCH #{count} FROM #{cursor_name}"

        rs = uninitialized PG::ResultSet

        Clear::SQL.log_query(fetch_query) { rs = cnx.query(fetch_query) }

        break unless fetch_result_set(h, rs) { |x| yield(x) }
      end
    end
  end

  # Get a scalar (EG count)
  #
  def scalar(type : T.class) forall T
    trigger_before_query

    Clear::SQL.log_query to_sql do
      Clear::SQL.connection.scalar(to_sql).as(T)
    end
  end

  def first
    limit(1).fetch { |x| return x }
  end

  def to_a : Array(Hash(String, ::Clear::SQL::Any))
    o = [] of Hash(String, ::Clear::SQL::Any)

    fetch do |x|
      o << x.dup
    end

    o
  end

  def fetch(&block : Hash(String, ::Clear::SQL::Any) -> Void)
    trigger_before_query

    h = {} of String => ::Clear::SQL::Any

    to_sql = self.to_sql

    rs = uninitialized PG::ResultSet
    Clear::SQL.log_query(to_sql) { rs = Clear::SQL.connection.query(to_sql) }

    fetch_result_set(h, rs) { |x| yield(x) }
  end
end
