require "db"

module Clear::SQL::Query::Execute
  def execute
    Clear::SQL.connection.exec(to_sql)
  end

  protected def fetch_result_set(h, rs, &block) : Int32
    lines = 0
    rs.each do
      rs.each_column do |col|
        h[col] = rs.read
      end

      yield(h)
      lines += 1
    end

    lines
  ensure
    rs.close
  end

  # Use a cursor to fetch the data
  def each_cursor(count = 1000, &block : Hash(String, ::Clear::SQL::Any) -> Void)
    Clear::SQL.connection.transaction do |tx|
      cnx = tx.connection
      cursor_name = "__cursor_#{Time.now.epoch ^ (rand*0xfffffff).to_i}__"
      cnx.exec("DECLARE #{cursor_name} CURSOR FOR #{to_sql}")

      n = count

      h = {} of String => ::Clear::SQL::Any

      while n == count
        cnx.query("FETCH #{count} FROM #{cursor_name}") { |rs| n = fetch_result_set(h, rs) { |x| yield(x) } }
      end
    end
  end

  def scalar(type : T.class) forall T
    Clear::SQL.connection.scalar(to_sql).as(T)
  end

  def each(&block : Hash(String, ::Clear::SQL::Any) -> Void)
    h = {} of String => ::Clear::SQL::Any

    Clear::SQL.connection.query(to_sql) do |rs|
      fetch_result_set(h, rs) { |x| yield(x) }
    end
  end
end
