module Clear::SQL::Query::Pluck
  # Select a specific column of your SQL query, execute the query
  # and return an array containing this field.
  #
  # ```crystal
  #   User.query.pluck_col("id") # [1,2,3,4...]
  # ```
  #
  # Note: It returns an array of `Clear::SQL::Any`. Therefore, you may want to use `pluck_col(str, Type)` to return
  #       an array of `Type`:
  #
  # ```crystal
  #   User.query.pluck_col("id", Int64)
  # ```
  #
  # The field argument is a SQL fragment; it's not escaped (beware SQL injection) and allow call to functions
  # and aggregate methods:
  #
  #  ```crystal
  #    # ...
  #    User.query.pluck_col("CASE WHEN id % 2 = 0 THEN id ELSE NULL END AS id").each do
  #    # ...
  #  ```
  def pluck_col(field : String)
    sql = self.clear_select.select(field).to_sql
    rs = Clear::SQL.log_query(sql) { Clear::SQL::ConnectionPool.with_connection(connection_name, &.query(sql)) }

    o = [] of Clear::SQL::Any

    while rs.move_next
      o << rs.read
    end
    o
  ensure
    rs.try &.close
  end

  # See `pluck_col(field)`
  def pluck_col(field : String, type : T.class ) forall T
    sql = self.clear_select.select(field).to_sql
    rs = Clear::SQL.log_query(sql) { Clear::SQL::ConnectionPool.with_connection(connection_name, &.query(sql)) }

    o = [] of T

    while rs.move_next
      o << rs.read(T)
    end
    o
  ensure
    rs.try &.close
  end

  # Select specifics columns and return an array of Tuple(*Clear::SQL::Any) containing the columns in the order of the selected
  # arguments:
  #
  # ```crystal
  #   User.query.pluck("first_name", "last_name").each do |(first_name, last_name)|
  #     #...
  #   end
  # ```
  def pluck(*fields)
    pluck(fields)
  end

  # Select specifics columns and returns on array of tuple of type of the named tuple passed as parameter:
  #
  # ```crystal
  #   User.query.pluck(id: Int64, "UPPER(last_name)": String).each do #...
  # ```

  def pluck(**fields : **T) forall T
    sql = self.clear_select.select(fields.keys.join(", ")).to_sql
    rs = Clear::SQL.log_query(sql) { Clear::SQL::ConnectionPool.with_connection(connection_name, &.query(sql)) }

    {% begin %}
      o = [] of Tuple({% for k,v in T %}{{v.instance}},{% end %})

      while rs.move_next
        o << { {% for k,v in T  %} rs.read({{v.instance}}), {% end %}}
      end
      o
    {% end %}
  ensure
    rs.try &.close
  end

  # See `pluck(*fields)`
  def pluck(fields : Tuple(*T)) forall T
    sql = self.clear_select.select(fields.join(", ")).to_sql
    rs = Clear::SQL.log_query(sql) { Clear::SQL::ConnectionPool.with_connection(connection_name, &.query(sql)) }

    {% begin %}
      o = [] of Tuple({% for t in T %}Clear::SQL::Any,{% end %})

    while rs.move_next
        o << {
          {% for t in T %}
            rs.read,
          {% end %}
        }
    end
    o
    {% end %}
  ensure
    rs.try &.close
  end
end