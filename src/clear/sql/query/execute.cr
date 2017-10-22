require "db"

module Clear::SQL::Query::Execute
  def execute
    Clear::SQL.connection.exec(to_sql)
  end

  def to_rs(&block : Hash(String, ::Clear::SQL::Any) -> Void)
    h = {} of String => ::Clear::SQL::Any

    puts "#{to_sql}..."
    Clear::SQL.connection.query(to_sql) do |rs|
      rs.each do
        rs.each_column do |col|
          x = rs.read
          puts "#{col} => #{x.class}"
          h[col] = x
        end

        pp h
        yield(h)
      end
    end
  end
end
