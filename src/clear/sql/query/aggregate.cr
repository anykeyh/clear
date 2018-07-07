module Clear::SQL::Query::Aggregate
  # Use SQL `COUNT` over your query, and return this number as a Int64
  def count(type : X.class = Int64) forall X
    # save the `select` column clause to ensure non-mutability of the query
    columns = @columns.dup
    o = if (@offset || @limit || @group_bys)
          subquery = self.dup.clear_order_bys.clear_select.select("1")
          X.new(Clear::SQL.select("COUNT(*)").from({query_count: subquery}).scalar(Int64))
        else
          new_query = self.dup.clear_select.select("COUNT(*)")
          X.new(new_query.scalar(Int64))
        end
    @columns = columns

    return o
  end

  # Call an custom aggregation function, like MEDIAN or other
  # Note than COUNT, MIN, MAX and AVG are already conveniently mapped.
  def agg(field, x : X.class) forall X
    self.clear_select.select(field).scalar(X)
  end

  {% for x in %w(min max avg) %}
    # Call the SQL aggregation function {{x.upcase}}
    def {{x.id}}(field, x : X.class) forall X
      agg("{{x.id.upcase}}(#{field})", X)
    end
  {% end %}
end
