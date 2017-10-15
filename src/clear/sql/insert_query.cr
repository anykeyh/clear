# WIP, not working yet !
#
# An insert query
#
# cf. postgres documentation
# [ WITH [ RECURSIVE ] with_query [, ...] ]
# INSERT INTO table_name [ AS alias ] [ ( column_name [, ...] ) ]
#    { DEFAULT VALUES | VALUES ( { expression | DEFAULT } [, ...] ) [, ...] | query }
#    [ ON CONFLICT [ conflict_target ] conflict_action ]
#    [ RETURNING * | output_expression [ [ AS ] output_name ] [, ...] ]
#
#
#
#
class Clear::SQL::InsertQuery
  def initialize
  end

  # Fast insert system
  #
  # insert({field: "value"}).into(:table)
  #
  def insert(values : NamedTuple)
  end

  # Select the table where we want to insert the data.
  def into(table : Selectable)
  end

  # Used with values
  def columns(*args)
  end

  # Insert a batch of data, from CSV for example
  def batch_values(a : Array(T)) forall T
  end

  # Add some rules for conflict
  def on_conflict(conflict_rules : String)
  end

  def values(*args)
  end

  # Insert into ... (...) SELECT
  def values(select_query : SelectQuery)
  end
end
