
# Create and maintain your database views directly in the code.
# You could use the migration system to create and drop your views. However this
# is proven to be difficult, even more if you want to update a view which call
# subview.
#
# Keep in mind than rollback/migrate a view is a non-sense,
# since there's no data integrity to deal with in the first place.
#
# ## Example
#
# ```
#
# ```
#
# When you migrate using the migration system built-in, all the views registered
# are going to be destroyed.
# Then migration will apply and all the views are going to be recreated.
class Clear::View
  # register a new view.
  def self.register(&)
    view = Clear::View.new
    yield view

    raise "Your view need to have a name" if view.name == ""
    raise "View `#{view.name}` need to have a query body" if view.query == ""

    @@views[view.name] = view
  end

  def self.apply(direction, apply_cache = Set(String).new)
    @@views.values.each do |view|
      next if apply_cache.includes?(view.name)
      apply(direction, view.name, apply_cache)
    end
  end

  def self.apply(direction, view_name : String, apply_cache : Set(String))
    return if apply_cache.includes?(view_name)

    view = @@views[view_name]
    view.requirement.each{ |dep_view| apply(direction, dep_view, apply_cache) }

    Clear::SQL.execute( direction == :drop ? view.to_drop_sql : view.to_create_sql )
    apply_cache << view_name
  end

  def self.clear
    @@views = {} of String => Clear::View
  end

  @@views = {} of String => Clear::View

  getter name : String = ""
  getter query : String = ""
  getter requirement = [] of String
  getter connection : String = "default"
  getter materialized : Bool = false

  def name(value)
    @name = value
  end

  def query(query)
    @query = query
  end

  def connection(connection)
    @connection = connection
  end

  def materialized(mat)
    @materialized = mat
  end

  def require(req)
    @requirement << req
  end

  def to_drop_sql
    "DROP VIEW IF EXISTS #{@name}"
  end

  def to_create_sql
    { "CREATE OR REPLACE", ( @materialized ? "MATERIALIZED VIEW" : "VIEW" ) , @name, "AS", @query }.join(' ')
  end

end
