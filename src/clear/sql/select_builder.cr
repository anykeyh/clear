require "./query/**"

module Clear::SQL::SelectBuilder
  include Query::Change
  include Query::Connection
  include Query::Select
  include Query::From
  include Query::Join
  include Query::Where
  include Query::OrderBy
  include Query::GroupBy
  include Query::Having
  include Query::Window
  include Query::OffsetLimit
  include Query::Execute
  include Query::Lock
  include Query::Fetch
  include Query::BeforeQuery
  include Query::CTE
  include Query::WithPagination
  include Query::Aggregate

  def initialize(@distinct_value = nil,
                 @cte = {} of String => Clear::SQL::SelectBuilder | String,
                 @columns = [] of SQL::Column,
                 @froms = [] of SQL::From,
                 @joins = [] of SQL::Join,
                 @wheres = [] of Clear::Expression::Node,
                 @havings = [] of Clear::Expression::Node,
                 @windows = [] of {String, String},
                 @group_bys = [] of Symbolic,
                 @order_bys = [] of Clear::SQL::Query::OrderBy::Record,
                 @limit = nil,
                 @offset = nil,
                 @lock = nil,
                 @before_query_triggers = [] of -> Void)
  end

  # Duplicate the query
  def dup : self
    self.class.new(
      distinct_value: @distinct_value,
      cte: @cte.dup,
      columns: @columns.dup,
      froms: @froms.dup,
      joins: @joins.dup,
      wheres: @wheres.dup,
      havings: @havings.dup,
      windows: @windows.dup,
      group_bys: @group_bys.dup,
      order_bys: @order_bys.dup,
      limit: @limit,
      offset: @offset,
      lock: @lock,
      before_query_triggers: @before_query_triggers
    )
  end

  def to_sql : String
    [print_ctes,
     print_select,
     print_froms,
     print_joins,
     print_wheres,
     print_havings,
     print_windows,
     print_group_bys,
     print_order_bys,
     print_limit_offsets,
     print_lock].compact.reject(&.empty?).join(" ")
  end

  # Construct a delete query from this select query.
  # It uses only the `from` and the `where` clause fo the current select request.
  # Can be useful in some case, but
  #   use at your own risk !
  def to_delete
    raise QueryBuildingError.new("Cannot build a delete query " +
                                 "from a select with multiple or none `from` clauses") unless @froms.size == 1

    v = @froms[0].value

    raise QueryBuildingError.new("Cannot delete from a select with sub-select as `from` clause") if v.is_a?(SelectBuilder)

    DeleteQuery.new(from: v.dup, wheres: @wheres.dup)
  end
end
