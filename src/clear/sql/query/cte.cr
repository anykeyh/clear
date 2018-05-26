module Clear::SQL::Query::CTE
  alias CTEAuthorized = Clear::SQL::SelectBuilder | String
  getter cte : Hash(String, CTEAuthorized)

  def with_cte(name, request : CTEAuthorized)
    cte[name] = request
    change!
  end

  def with_cte(tuple : NamedTuple)
    tuple.each do |k,v|
      cte[k.to_s] = v
    end
    change!
  end

  protected def print_ctes
    if cte.any?
      o = "WITH "

      o += cte.map do |name, cte_declaration|

        value = if cte_declaration.responds_to?(:to_sql)
          cte_declaration.to_sql
        else
          cte_declaration.to_s
        end

        "#{name} AS (#{value})"
      end.join(", ")

      o
    end
  end
end
