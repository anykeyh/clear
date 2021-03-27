module Clear::SQL
  module Query::From
    getter froms : Array(SQL::From)

    # FROM fragment of the SQL query
    # ```crystal
    # Clear::SQL.select.from("airplanes").to_sql # < SELECT * FROM airplanes
    # ```
    def from(*__args)
      __args.each do |arg|
        case arg
        when NamedTuple
          arg.each { |k, v| @froms << Clear::SQL::From.new(v, k.to_s) }
        else
          @froms << Clear::SQL::From.new(arg)
        end
      end

      change!
    end

    def from(**__named_tuple)
      __named_tuple.each { |k, v| @froms << Clear::SQL::From.new(v, k.to_s) }
      change!
    end

    # Clear the FROM clause and return `self`
    def clear_from
      @froms.clear
      change!
    end

    protected def print_froms
      if @froms.any?
        "FROM " + @froms.join(", ", &.to_sql)
      end
    end
  end
end
