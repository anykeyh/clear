require "./fragment"

module Clear::SQL
  struct From < Fragment
    property value : Selectable
    property var : Symbolic?

    def initialize(@value, @var = nil)
    end

    def to_sql
      v = value
      case v
      when Symbol
        [Clear::SQL.escape(v), @var].compact.join(" AS ")
      when String
        [v, @var].compact.join(" AS ")
      when SQL::SelectBuilder
        raise Clear::ErrorMessages.query_building_error("Subquery `from` clause must have variable name") if @var.nil?
        ["(#{v.to_sql})", @var].compact.join(" ")
      else
        raise Clear::ErrorMessages.query_building_error("Only String and SelectQuery objects are allowed as `from` declaration")
      end
    end
  end
end
