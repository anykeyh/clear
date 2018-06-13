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
      when Symbolic
        [v, @var].compact.join(" AS ")
      when SQL::SelectBuilder
        raise QueryBuildingError.new("Subquery `from` clause must have variable name") if @var.nil?
        ["( #{v.to_sql} )", @var].compact.join(" ")
      else
        raise QueryBuildingError.new("Only String and SelectQuery are allowed as column declaration")
      end
    end
  end
end
