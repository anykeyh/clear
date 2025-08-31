# Allow usage of Common Table Expressions (CTE) in the query building
module Clear::SQL::Query::CTE
  # :nodoc:
  alias CTEAuthorized = Clear::SQL::SelectBuilder | String

  record Record, query : CTEAuthorized, recursive : Bool

  # List the current CTE of the query. The key is the name of the CTE,
  # while the value is the fragment (string or Sub-select)
  getter cte : Hash(String, Clear::SQL::Query::CTE::Record) = {} of String => Clear::SQL::Query::CTE::Record

  # Add a CTE to the query.
  #
  # ```
  # Clear::SQL.select.with_cte("full_year",
  #   "SELECT DATE(date)"
  #   "FROM generate_series(NOW() - INTERVAL '1 year', NOW(), '1 day'::interval) date")
  #   .select("*").from("full_year")
  # # WITH full_year AS ( SELECT DATE(date) ... ) SELECT * FROM full_year;
  # ```
  def with_cte(name, request : CTEAuthorized, recursive = false)
    cte[name] = Record.new(request, recursive)
    change!
  end

  # Add a CTE to the query. Use NamedTuple convention:
  #
  # ```
  # Clear::SQL.select.with_cte(cte: "xxx")
  # # WITH cte AS xxx SELECT...
  # ```
  def with_cte(tuple : NamedTuple)
    tuple.each do |k, v|
      cte[k.to_s] = Record.new(v, false)
    end
    change!
  end

  # Add a CTE to the query. Use NamedTuple convention:
  #
  # ```
  # Clear::SQL.select.with_recursive_cte(cte: "xxx")
  # # WITH RECURSIVE cte AS xxx SELECT...
  # ```
  def with_recursive_cte(tuple : NamedTuple)
    tuple.each do |k, v|
      cte[k.to_s] = Record.new(v, true)
    end
    change!
  end

  # :nodoc:
  protected def print_ctes
    return if cte.empty?

    {"WITH ",
     cte.join(", ") do |name, v|
       query = v.query
       value = query.responds_to?(:to_sql) ? query.to_sql : query.to_s
       {v.recursive ? "RECURSIVE" : "",
        name, " AS (", value, ")"}.join
     end,
    }.join
  end
end
