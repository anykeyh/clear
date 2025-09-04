module Clear::SQL::Query::Pluck
  # Select a specific column of your SQL query, execute the query
  # and return an array containing this field.
  #
  # ```
  # User.query.pluck_col("id") # [1,2,3,4...]
  # ```
  #
  # Note: It returns an array of `Clear::SQL::Any`. Therefore, you may want to use `pluck_col(str, Type)` to return
  #       an array of `Type`:
  #
  # ```
  # User.query.pluck_col("id", Int64)
  # ```
  #
  # The field argument is a SQL fragment; it's not escaped (beware SQL injection) and allow call to functions
  # and aggregate methods:
  #
  #  ```
  #    # ...
  #    User.query.pluck_col("CASE WHEN id % 2 = 0 THEN id ELSE NULL END AS id").each do
  #    # ...
  #  ```
  def pluck_col(field : Clear::SQL::Symbolic)
    field = Clear::SQL.escape(field) if field.is_a?(Symbol)

    sql = self.clear_select.select(field).to_sql

    Clear::SQL::ConnectionPool.with_connection(connection_name) do |cnx|
      rs = Clear::SQL.log_query(sql) { cnx.query(sql) }

      o = [] of Clear::SQL::Any

      while rs.move_next
        o << rs.read.as(::Clear::SQL::Any)
      end
      o
    ensure
      rs.try &.close
    end
  end

  # :ditto:
  def pluck_col(field : Clear::SQL::Symbolic, type : T.class) forall T
    field = Clear::SQL.escape(field) if field.is_a?(Symbol)

    sql = self.clear_select.select(field).to_sql

    Clear::SQL::ConnectionPool.with_connection(connection_name) do |cnx|
      rs = Clear::SQL.log_query(sql) { cnx.query(sql) }

      o = [] of T

      while rs.move_next
        o << rs.read(T)
      end

      o
    ensure
      rs.try &.close
    end
  end

  # Select specifics columns and return an array of Tuple(*Clear::SQL::Any) containing the columns in the order of the selected
  # arguments:
  #
  # ```
  # User.query.pluck("first_name", "last_name").each do |(first_name, last_name)|
  #   # ...
  # end
  # ```
  def pluck(*fields)
    pluck(fields)
  end

  # :ditto:
  def pluck(fields : Tuple(*T)) forall T
    select_clause = fields.join(", ") { |f| f.is_a?(Symbol) ? Clear::SQL.escape(f) : f.to_s }
    sql = self.clear_select.select(select_clause).to_sql

    Clear::SQL::ConnectionPool.with_connection(connection_name) do |cnx|
      rs = Clear::SQL.log_query(sql) { cnx.query(sql) }

      {% begin %}
        o = [] of Tuple({% for t in T %}Clear::SQL::Any,{% end %})

        while rs.move_next
            o << { {% for t in T %} rs.read.as(::Clear::SQL::Any), {% end %} }
        end
        o
      {% end %}
    ensure
      rs.try &.close
    end
  end

  # Select specifics columns and returns on array of tuple of type of the named tuple passed as parameter:
  #
  # ```
  #   User.query.pluck(id: Int64, "UPPER(last_name)": String).each do #...
  # ```
  def pluck(**fields : **T) forall T
    sql = clear_select.select(fields.keys.join(", ")).to_sql

    Clear::SQL::ConnectionPool.with_connection(connection_name) do |cnx|
      rs = Clear::SQL.log_query(sql) { cnx.query(sql) }

      {% begin %}
        o = [] of Tuple({% for k, v in T %}{{v.instance}},{% end %})

        while rs.move_next
          o << { {% for k, v in T %} rs.read({{v.instance}}), {% end %}}
        end
        o
      {% end %}
    ensure
      rs.try &.close
    end
  end
end
