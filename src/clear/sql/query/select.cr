module Clear::SQL::Query::Select
  macro included
    getter columns : Array(SQL::Column) = [] of SQL::Column
  end

  # def select(name : Symbolic, var = nil)
  #  @columns << Column.new(name, var)
  #  self
  # end
  def select(c : Column)
    @columns << c
    self
  end

  # Add field(s) to selection from tuple
  # ```
  #  select({user_id: "uid", updated_at: "updated_at"})
  #  # => Output "SELECT user_id as uid, updated_at as updated_at"
  # ```
  def select(*args)
    args.each do |arg|
      case arg
      when NamedTuple
        arg.each { |k, v| @columns << Column.new(v, k.to_s) }
      else
        @columns << Column.new(arg)
      end
    end

    self
  end

  def clear_select
    @columns.clear
    self
  end
end
