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

  def do_update(&)
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

  def on_conflict(&)
    condition = OnConflictWhereClause.new
    condition.where(
      Clear::Expression.ensure_node!(with Clear::Expression.new yield)
    )
    @on_conflict_condition = condition
    change!
  end

  def conflict?
    !!@on_conflict_condition
  end

  def clear_conflict
    @on_conflict_condition = false
  end

  protected def print_on_conflict(o : Array)
    if c = @on_conflict_condition
      o << "ON CONFLICT"

      unless c == true
        o << c.to_s
      end

      a = @on_conflict_action
      o << "DO" << (a.is_a?(String) ? a.to_s : a.to_sql)
    end
  end
end
