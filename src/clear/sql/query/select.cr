module Clear::SQL::Query::Select
  macro included
    getter columns : Array(SQL::Column) = [] of SQL::Column
    getter default_wildcard_table = nil

    def is_distinct?
      !!@distinct_value
    end
  end

  @columns : Array(SQL::Column)
  getter distinct_value : String?

  # In some case you want you query to return `table.*` instead of `*`
  #   if no select parameters has been set. This occurs in the case of joins
  #   between models.
  def set_default_table_wildcard(table : String? = nil)
    @default_wildcard_table = table
    change!
  end

  # def select(name : Symbolic, var = nil)
  #  @columns << Column.new(name, var)
  #  self
  # end
  def select(c : Column)
    @columns << c
    change!
  end

  # Add DISTINCT to the SELECT part of the query
  #
  # - If on is blank (empty string, default), will call a simple `SELECT DISTINCT ...`
  # - If on is nil, will remove the distinct (see `undistinct`)
  # - If on is a non empty string, will call `SELECT DISTINCT ON (on) ...`
  #
  def distinct(on : String? = "")
    @distinct_value = on
    change!
  end

  # Remove distinct
  def undistinct
    distinct nil
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

    change!
  end

  def clear_select
    @columns.clear
    change!
  end

  protected def print_distinct
    case @distinct_value
    when nil
      ""
    when ""
      "DISTINCT "
    else
      {"DISTINCT ON (", @distinct_value, ") "}.join
    end
  end

  protected def print_wildcard
    if table = @default_wildcard_table
      {table, "*"}.join('.')
    else
      "*"
    end
  end

  protected def print_columns
    (@columns.any? ? @columns.map(&.to_sql.as(String)).join(", ") : print_wildcard)
  end

  protected def print_select
    {"SELECT ", print_distinct, print_columns}.join
  end
end
