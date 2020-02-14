# :nodoc:
# NOT YET IMPLEMENTED
# A view is like a read-only model.
# It has columns and relations
# It is automatically updated on migration by the migration manager
# ```crystal
# class MyView
#   define <<-SQL
#     SELECT * FROM users, other_views
#   SQL
#
#   depends_of OtherViews
# end
# ```
module Clear::View
  def self.depends_of(x : Class(T)) forall T
    @@dependancies << x
  end

  def self.define(x)
    case x
    when String
      @@sql = x
    when Clear::SQLBuilder
      @@sql = x.to_sql
    end
  end

  include Clear::Model::HasColumns
  include Clear::Model::HasRelations
  include Clear::Model::HasScope
  include Clear::Model::ClassMethods
end
