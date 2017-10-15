module Clear::SQL
  module Query::From
    getter froms : Array(SQL::From)

    def from(*args)
      args.each do |arg|
        case arg
        when NamedTuple
          arg.each { |k, v| @froms << Clear::SQL::From.new(v, k.to_s) }
        else
          @froms << Clear::SQL::From.new(arg)
        end
      end

      self
    end

    def clear_from
      @froms.clear
      self
    end

    protected def print_froms
      if @froms.any?
        "FROM " + @froms.map(&.to_sql).join(", ")
      end
    end
  end
end
