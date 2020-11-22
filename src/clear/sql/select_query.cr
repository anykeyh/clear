require "./query/*"
require "./select_builder"
require "./sql"

# A Select Query builder
#
# Remember of PostgreSQL Select query:
#
# ```
# [ WITH [ RECURSIVE ] with_query [, ...] ]
# SELECT [ ALL | DISTINCT [ ON ( expression [, ...] ) ] ]
#     [ * | expression [ [ AS ] output_name ] [, ...] ]
#     [ FROM from_item [, ...] ]
#     [ WHERE condition ]
#     [ GROUP BY grouping_element [, ...] ]
#     [ HAVING condition [, ...] ]
#     [ WINDOW window_name AS ( window_definition ) [, ...] ]
#     [ { UNION | INTERSECT | EXCEPT } [ ALL | DISTINCT ] select ]
#     [ ORDER BY expression [ ASC | DESC | USING operator ] [ NULLS { FIRST | LAST } ] [, ...] ]
#     [ LIMIT { count | ALL } ]
#     [ OFFSET start [ ROW | ROWS ] ]
#     [ FETCH { FIRST | NEXT } [ count ] { ROW | ROWS } ONLY ]
#     [ FOR { UPDATE | NO KEY UPDATE | SHARE | KEY SHARE } [ OF table_name [, ...] ] [ NOWAIT | SKIP LOCKED ] [...] ]
# ```
class Clear::SQL::SelectQuery
  include Enumerable(Hash(String, Clear::SQL::Any))
  include SelectBuilder

  # Enumerable items
  def each
    fetch { |h| yield(h) }
  end

  def count(&block)
    to_a.count(&block)
  end

  def size
    to_a.size
  end
end
