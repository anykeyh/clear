require "./where"

module Clear::SQL::Query::OnConflict
  getter on_conflict_condition : String | OnConflictWhereClause | Bool = false
  getter on_conflict_action : String | Clear::SQL::UpdateQuery = "NOTHING"

  # Fragment used when ON CONFLICT WHERE ...
  class OnConflictWhereClause
    include Query::Where

    def initialize
      @wheres = [] of Clear::Expression::Node
    end

    def to_s
      print_wheres
    end

    def change!
    end
  end

  def do_conflict_action(str)
    @on_conflict_action = "#{str}"
    change!
  end

  def do_update(&block)
    action = Clear::SQL::UpdateQuery.new(nil)
    yield(action)
    @on_conflict_action = action
    change!
  end

  def do_nothing
    @on_conflict_action = "NOTHING"
    change!
  end

  def on_conflict(constraint : String | Bool | OnConflictWhereClause = true)
    @on_conflict_condition = constraint
    change!
  end

  def on_conflict(&block)
    condition = OnConflictWhereClause.new
    condition.where(
      Clear::Expression.ensure_node!(with Clear::Expression.new yield)
    )
    @on_conflict_condition = condition
    change!
  end

  def has_conflict?
    !!@on_conflict_condition
  end

  def clear_conflict
    @on_conflict_condition = false
  end
end
