require "./fragment"

module Clear::SQL
  struct Join < Fragment
    TYPE = {left:       "LEFT JOIN",
            inner:      "INNER JOIN",
            right:      "RIGHT JOIN",
            full_outer: "FULL OUTER JOIN",
            cross:      "CROSS JOIN"}

    property type : String
    property from : Selectable
    property condition : Clear::Expression::Node?

    def initialize(@from, @condition = nil, type : Symbolic = :inner)
      @type = if type.is_a?(Symbol)
                TYPE[type] || raise Clear::ErrorMessages.query_building_error("Type of join unknown: `#{type}`")
              else
                type
              end
    end

    def to_sql
      c = condition
      if c
        "#{type} #{SQL.sel_str(from)} ON (#{c.resolve})"
      else
        "#{type} #{SQL.sel_str(from)}"
      end
    end
  end
end
