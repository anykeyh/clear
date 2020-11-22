require "./fragment"

module Clear::SQL
  struct Join < Fragment
    TYPE = {left:       "LEFT JOIN",
            inner:      "INNER JOIN",
            right:      "RIGHT JOIN",
            full_outer: "FULL OUTER JOIN",
            cross:      "CROSS JOIN"}

    getter type : String
    getter from : Selectable
    getter condition : Clear::Expression::Node?
    getter lateral : Bool

    def initialize(@from, @condition = nil, @lateral = false, type : Symbol = :inner)
      @type = TYPE.fetch(type) { raise Clear::ErrorMessages.query_building_error("Type of join unknown: `#{type}`") }
    end

    def to_sql
      from = @from

      from = case from
             when SQL::SelectBuilder
               "(#{from.to_sql})"
             else
               from.to_s
             end

      if c = @condition
        [type,
         lateral ? "LATERAL" : nil,
         from,
         "ON",
         c.resolve].compact.join(" ")
      else
        [type, lateral ? "LATERAL" : nil, SQL.sel_str(from)].compact.join(" ")
      end
    end
  end
end
