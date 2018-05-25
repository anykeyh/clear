module Clear::SQL::Query::CTE
  alias CTEAuthorized = Clear::SQL::SelectBuilder | String
  getter cte : Hash(String, CTEAuthorized)

  def with_cte(request : CTEAuthorized)
    cte
    change!
  end

  protected def print_ctes
    if cte.any?
      o = ["WITH "]
      (o + cte.map do |name, cte_declaration|
        cte_string = case cte_declaration
                     when String
                       cte
                     when Clear::SQL::SelectBuilder
                       cte.to_sql
                     end
        [name, "AS", "(", cte_string, ")"]
      end).join(", ")
    end
  end
end
