module Clear::SQL::Query::Select
  macro included
    getter columns : Array(SQL::Column) = [] of SQL::Column
    getter default_wildcard_table = nil

    def is_distinct?
      !!@distinct_value
    end
  end

  @columns : Array(SQL::Column)
  @forced_columns : Array(SQL::Column)

  getter distinct_value : String?

  # In some case you want you query to return `table.*` instead of `*`
  #   if no select parameters has been set. This occurs in the case of joins
  #   between models.
  def set_default_table_wildcard(table : String? = nil)
    @default_wildcard_table = table
    change!
  end

  # :nodoc:
  def select(c : Column)
    @columns << c
    change!
  end

  def force_select(c : Column)
    @forced_columns << c
    change!
  end

  # Add DISTINCT to the SELECT part of the query
  #
  # - If `on` is blank (empty string, default), will call a simple `SELECT DISTINCT ...`
  # - If `on` is nil, will remove the distinct (see `clear_distinct`)
  # - If `on` is a non empty string, will call `SELECT DISTINCT ON (on) ...`
  #
  def distinct(on : String? = "")
    @distinct_value = on
    change!
  end

  # Remove distinct
  def clear_distinct
    distinct nil
  end

  # Add columns in the SELECT query.
  # By default, a new SELECT query will select all using wildcard `*`.
  #
  # After a call to select is made, the query will select the given fields instead.
  #
  # ```
  #  select(user_id: "uid", updated_at: "updated_at")
  #  # => Output "SELECT user_id as uid, updated_at as updated_at"
  # ```
  def select(*__args)
    __args.each do |arg|
      case arg
      when NamedTuple
        arg.each { |k, v| @columns << Column.new(v, k.to_s) }
      else
        @columns << Column.new(arg)
      end
    end

    change!
  end

  # Act as `select` method, but is not cleared by `clear_select`
  #
  # This is useful for enriching a query which absolutely need some key colums,
  # for example this is used in relations caching under the hood.
  #
  # ```
  #  query.force_select("id")
  #  query.select("a, b").to_sql  # => Output "SELECT a, b, id"
  #  query.clear_select.to_sql    # => Output "SELECT *, id"
  # ```
  def force_select(*__args)
    __args.each do |arg|
      case arg
      when NamedTuple
        arg.each { |k, v| @forced_columns << Column.new(v, k.to_s) }
      else
        @forced_columns << Column.new(arg)
      end
    end

    change!
  end

  def select(**__tuple)
    __tuple.each { |k, v| @columns << Column.new(v, k.to_s) }
    change!
  end

  def force_select(**__tuple)
    __tuple.each { |k, v| @forced_columns << Column.new(v, k.to_s) }
    change!
  end

  def clear_select
    @columns.clear
    change!
  end

  def clear_force_select
    @forced_columns.clear
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

  protected def print_forced_columns
    if @forced_columns.any?
      ", " + @forced_columns.map(&.to_sql.as(String)).join(", ")
    else
      ""
    end
  end

  protected def print_select
    {"SELECT ", print_distinct, print_columns, print_forced_columns}.join
  end
end
