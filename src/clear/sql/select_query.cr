require "./query/*"
require "./select_builder"

# A Select Query builder
# Cf. Postgres documentation
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
#
class Clear::SQL::SelectQuery
  include SelectBuilder
end
