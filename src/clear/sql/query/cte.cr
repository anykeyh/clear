# Allow usage of Common Table Expressions (CTE) in the query building
module Clear::SQL::Query::CTE
  # :nodoc:
  alias CTEAuthorized = Clear::SQL::SelectBuilder | String

  # List the current CTE of the query. The key is the name of the CTE,
  # while the value is the fragment (string or Sub-select)
  getter cte : Hash(String, CTEAuthorized) = {} of String => CTEAuthorized

  # Add a CTE to the query.
  #
  # ```crystal
  # Clear::SQL.select.with_cte("full_year",
  #   "SELECT DATE(date)"
  #   "FROM generate_series(NOW() - INTERVAL '1 year', NOW(), '1 day'::interval) date")
  #   .select("*").from("full_year")
  # # WITH full_year AS ( SELECT DATE(date) ... ) SELECT * FROM full_year;
  # ```
  def with_cte(name, request : CTEAuthorized)
    cte[name] = request
    change!
  end

  # Add a CTE to the query. Use NamedTuple convention:
  #
  # ```crystal
  # Clear::SQL.select.with_cte(cte: "xxx")
  # # WITH cte AS xxx SELECT...
  # ```
  def with_cte(tuple : NamedTuple)
    tuple.each do |k, v|
      cte[k.to_s] = v
    end
    change!
  end

  # :nodoc:
  protected def print_ctes
    if cte.any?
      {"WITH ",
       cte.map do |name, cte_declaration|
         value = if cte_declaration.responds_to?(:to_sql)
                   cte_declaration.to_sql
                 else
                   cte_declaration.to_s
                 end

         {name, " AS (", value, ")"}.join
       end.join(", "),
      }.join
    end
  end
end
