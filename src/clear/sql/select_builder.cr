module Clear::SQL::SelectBuilder
  getter havings : Array(Clear::Expression::Node)

  def initialize(@is_distinct = false,
                 @cte = {} of String => Query::CTE::CTEAuthorized,
                 @columns = [] of SQL::Column,
                 @froms = [] of SQL::From,
                 @joins = [] of SQL::Join,
                 @wheres = [] of Clear::Expression::Node,
                 @havings = [] of Clear::Expression::Node,
                 @group_bys = [] of String,
                 @order_bys = [] of Clear::SQL::Query::OrderBy::Record,
                 @limit = nil,
                 @offset = nil,
                 @lock = nil,
                 @before_query_triggers = [] of -> Void)
  end

  include Query::Change
  include Query::Select
  include Query::From
  include Query::Join
  include Query::Where
  include Query::OrderBy
  include Query::GroupBy
  include Query::OffsetLimit
  include Query::Execute
  include Query::Lock
  include Query::Fetch
  include Query::BeforeQuery
  include Query::CTE
  include Query::WithPagination
  include Query::Aggregate

  def dup : self
    self.class.new(columns: @columns.dup,
      froms: @froms.dup,
      joins: @joins.dup,
      wheres: @wheres.dup,
      havings: @havings.dup,
      group_bys: @group_bys.dup,
      order_bys: @order_bys.dup,
      limit: @limit,
      offset: @offset,
      lock: @lock
    )
  end

  def to_sql : String
    [print_ctes,
     print_columns,
     print_froms,
     print_joins,
     print_wheres,
     print_havings,
     print_group_bys,
     print_order_bys,
     print_limit_offsets,
     print_lock].compact.reject(&.empty?).join(" ")
  end

  def to_delete
    raise QueryBuildingError.new("Cannot build a delete query " +
                                 "from a select with multiple or none from clauses") unless @froms.size == 1

    v = @froms[0].value

    raise QueryBuildingError.new("Cannot delete from a select with sub-select as from clause") if v.is_a?(SelectBuilder)

    DeleteQuery.new(from: v.dup, wheres: @wheres.dup)
  end

  protected def print_havings
    return unless @havings.any?
    "HAVING " + @havings.map(&.resolve).join(" AND ")
  end
end
