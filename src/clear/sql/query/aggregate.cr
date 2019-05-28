module Clear::SQL::Query::Aggregate
  # Use SQL `COUNT` over your query, and return this number as a Int64
  #
  # as count return always a scalar, the usage of `COUNT(*) OVER GROUP BY` can be done by
  # using `pluck` or `select`
  #
  #
  def count(type : X.class = Int64) forall X
    # save the `select` column clause to ensure non-mutability of the query
    columns = @columns.dup

    # In case of group by or pagination,
    # to have the count of records.
    if (@offset || @limit || @group_bys)
      # SELECT COUNT(query_count.*) FROM ( $subquery query_count )

      # Optimize returning 1 if found, as we count only...
      # ... except if the subquery has distinct, otherwise will always returns "1"...
      subquery = self.is_distinct? ? self : self.dup.clear_order_bys.clear_select.use_connection(self.connection_name).select("1")

      o = X.new(Clear::SQL.select("COUNT(*)").from({query_count: subquery}).scalar(Int64))
    else
      new_query = self.dup.clear_select.select("COUNT(*)")
      o = X.new(new_query.scalar(Int64))
    end
    @columns = columns

    o
  end

  # Call an custom aggregation function, like MEDIAN or other:
  #
  # ```
  # query.agg("MEDIAN(age)", Int64)
  # ```
  #
  # Note than COUNT, MIN, MAX, SUM and AVG are already conveniently mapped.
  #
  # This return only one row, and should not be used with `group_by` (prefer pluck or fetch)
  def agg(field, x : X.class) forall X
    self.clear_select.select(field).scalar(X)
  end

  # SUM through a field and return a Float64
  # Note: This function is not safe injection-wise, so beware !.
  def sum(field) : Float64
    agg("SUM(#{field})", Union(Int64 | PG::Numeric | Nil)).try(&.to_f) || 0.0
  end

  {% for x in %w(min max avg) %}
    # SQL aggregation function {{x.upcase}}:
    #
    # ```
    #   query.{{x.id}}("field", Int64)
    # ```
    def {{x.id}}(field, x : X.class) forall X
      agg("{{x.id.upcase}}(#{field})", X)
    end
  {% end %}
end
