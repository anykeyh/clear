require "../sql/select_query"

module Clear::Model
  # The query collection system
  # Every time a collection is created when you call `Model.query`
  # or call any defined scope
  class CollectionBase(T)
    include Clear::SQL::SelectBuilder

    # Used for build from collection
    @tags : Hash(String, Clear::SQL::Any)

    # Redefinition of the fields,
    # because of a bug in the compiler (crystal issue #5281)
    @limit : Int64?
    @offset : Int64?
    @lock : String?

    # :nodoc:
    @cache : Clear::Model::QueryCache

    # :nodoc:
    @cached_result : Array(T)?

    # :nodoc:
    def initialize(
      @cte = {} of String => Clear::SQL::Query::CTE::CTEAuthorized,
      @columns = [] of SQL::Column,
      @froms = [] of SQL::From,
      @joins = [] of SQL::Join,
      @wheres = [] of Clear::Expression::Node,
      @havings = [] of Clear::Expression::Node,
      @group_bys = [] of SQL::Column,
      @order_bys = [] of String,
      @limit = nil,
      @offset = nil,
      @lock = nil,
      @tags = {} of String => Clear::SQL::Any,
      @before_query_triggers = [] of -> Void,
      @cache = Clear::Model::QueryCache.new,
      @cached_result = nil
    )
    end

    # :nodoc:
    def cached(cache : Clear::Model::QueryCache)
      @cache = cache
      self
    end

    # :nodoc:
    def with_cached_result(r : Array(T))
      @cached_result = r
      self
    end

    # :nodoc:
    def clear_cached_result
      @cached_result = nil
      self
    end

    # :nodoc:
    def change!
      # In case we filter this collection, we remove the cache
      clear_cached_result
    end

    # :nodoc:
    def tags(x : NamedTuple)
      @tags.merge!(x.to_h)
      self
    end

    # :nodoc:
    def tags(x : Hash(String, X)) forall X
      @tags.merge!(x.to_h)
      self
    end

    # :nodoc:
    def clear_tags
      @tags = {} of String => Clear::SQL::Any
      self
    end

    # Build the SQL, send the query then iterate through each models
    # gathered by the request.
    def each(fetch_columns = false, &block : T ->)
      cr = @cached_result

      if cr
        cr.each(&block)
      else
        fetch(fetch_all: true) do |hash|
          yield(T.factory.build(hash, persisted: true, fetch_columns: fetch_columns, cache: @cache))
        end
      end
    end

    # Build the SQL, send the query then build and array by applying the
    # block transformation over it.
    def map(fetch_columns = false, &block : T -> X) : Array(X) forall X
      o = [] of X
      each(fetch_columns) { |mdl| o << block.call(mdl) }
      o
    end

    # Build the SQL, send the query then iterate through each models
    # gathered by the request.
    # Use a postgres cursor to avoid memory bloating.
    # Useful to fetch millions of rows at once.
    def each_with_cursor(batch = 1000, fetch_columns = false, &block : T ->)
      cr = @cached_result

      if cr
        cr.each(&block)
      else
        self.fetch_with_cursor(count: batch) do |hash|
          yield(T.factory.build(hash, persisted: true, fetch_columns: fetch_columns, cache: @cache))
        end
      end
    end

    # Build a new collection; if the collection comes from a has_many relation
    # (e.g. `my_model.associations.build`), the foreign column which store
    # the primary key of `my_model` will be setup by default, preventing you
    # to forget it.
    def build : T
      pp @tags
      T.factory.build(@tags, persisted: false)
    end

    # Build a new collection; if the collection comes from a has_many relation
    # (e.g. `my_model.associations.build`), the foreign column which store
    # the primary key of `my_model` will be setup by default, preventing you
    # to forget it.
    # You can pass extra parameters using a named tuple:
    # `my_model.associations.build({a_column: "value"}) `
    def build(x : NamedTuple) : T
      T.factory.build(@tags.merge(x.to_h), persisted: false)
    end

    # Check whether the query return any row.
    def any?
      cr = @cached_result

      return cr.any? if cr

      self.clear_select.select("1").limit(1).fetch do |_|
        return true
      end

      return false
    end

    # Inverse of `any?`, return true if the request return no rows.
    def empty?
      not any?
    end

    # Use SQL `COUNT` over your query, and return this number as a Int64
    def count(what = "*") : Int64
      cr = @cached_result

      return Int64.new(cr.size) if cr

      self.clear_select.select("COUNT(#{what})").scalar(Int64)
    end

    # Call an custom aggregation function, like MEDIAN or other
    # Note than COUNT, MIN, MAX and AVG are conveniently mapped.
    def agg(field, x : T.class) forall T
      self.clear_select.select(field).scalar.as(T)
    end

    {% for x in %w(min max avg) %}
      # Call the SQL aggregation function {{x.upcase}}
      def {{x.id}}(field, x : T.class) forall T
        agg("{{x.id.upcase}}(#{field})", T)
      end
    {% end %}

    # Create an array from the query.
    def to_a(fetch_columns = false) : Array(T)
      cr = @cached_result

      return cr if cr

      out = [] of T
      each(fetch_columns: fetch_columns) { |m| out << m }
      out
    end

    # Basically a custom way to write `OFFSET x LIMIT 1`
    def [](off) : T
      self.[]?(off).not_nil!
    end

    # Basically a custom way to write `OFFSET x LIMIT 1`
    def []?(off) : T?
      self.offset(off).first
    end

    # A convenient way to write `where{ condition }.first`
    def find(&block) : T?
      x = Clear::Expression.to_node(with Clear::Expression.new yield)
      where(x).first
    end

    # A convenient way to write `where({any_column: "any_value"}).first`
    def find(tuple : NamedTuple) : T?
      where(tuple).first
    end

    # A convenient way to write `where({any_column: "any_value"}).first!`
    def find!(&block) : T
      x = Clear::Expression.to_node(with Clear::Expression.new yield)
      where(x).first!
    end

    # A convenient way to write `where{ condition }.first!`
    def find!(tuple : NamedTuple) : T
      where(tuple).first.not_nil!
    end

    # Try to fetch a row. If not found, build a new object and setup
    # the fields like setup in the condition tuple.
    def find_or_build(tuple : NamedTuple, &block : T -> Void) : T
      r = where(tuple).first

      return r if r

      str_hash = {} of String => Clear::SQL::Any

      tuple.map { |k, v| str_hash[k.to_s] = v }
      str_hash.merge!(@tags)

      r = T.factory.build(str_hash)
      yield(r)

      r
    end

    # Try to fetch a row. If not found, build a new object and setup
    # the fields like setup in the condition tuple.
    # Just after building, save the object.
    def find_or_create(tuple : NamedTuple, &block : T -> Void) : T
      r = find_or_build(tuple, &block)
      r.save
      r
    end

    # Get the first row from the collection query.
    # if not found, throw an error
    def first! : T
      first.not_nil!
    end

    # Get the first row from the collection query.
    # if not found, return `nil`
    def first : T?
      order_by("#{T.pkey} ASC") unless T.pkey.nil? || order_bys.any?

      limit(1).fetch do |hash|
        return T.factory.build(hash, persisted: true, cache: @cache)
      end

      return nil
    end

    # Get the last row from the collection query.
    # if not found, return `nil`
    def last! : T
      last.not_nil!
    end

    # Get the last row from the collection query.
    # if not found, return `nil`
    # TODO: NOT WORKING YET IF ORDER BY MANUALLY SET.
    # Must handle order_by clauses differently
    def last : T?
      order_by("#{T.pkey} DESC") unless T.pkey.nil? || order_bys.any?

      limit(1).fetch do |hash|
        return T.factory.build(hash, persisted: true, cache: @cache)
      end

      return nil
    end

  end
end
