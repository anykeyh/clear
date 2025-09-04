# Column in SQL Select query
#
# ```
# c = SQL::Column.new("COUNT(*)", "count")
# c.to_sql # 'COUNT(*) as count'
# ```
require "./fragment"

module Clear::SQL
  struct Column < Fragment
    property value : Selectable
    property var : Symbolic?

    def initialize(@value, @var = nil)
    end

    def to_sql
      v = value
      case v
      when String
        [v, @var].compact.join(" AS ")
      when Symbol
        [SQL.escape(v.to_s), @var].compact.join(" AS ")
      when SQL::SelectBuilder
        ["( #{v.to_sql} )", @var].compact.join(" AS ")
      else
        raise QueryBuildingError.new("Only String and SelectQuery are allowed as column declaration")
      end
    end
  end
end
