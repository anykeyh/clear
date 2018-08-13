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
    # because of a bug in the compiler
    # https://github.com/crystal-lang/crystal/issues/5281
    @limit : Int64?
    @offset : Int64?
    @lock : String?
    @distinct_value : String?

    # :nodoc:
    @cache : Clear::Model::QueryCache

    # :nodoc:
    @cached_result : Array(T)?

    # :nodoc:
    def initialize(
      @distinct_value = nil,
      @cte = {} of String => Clear::SQL::SelectBuilder | String,
      @columns = [] of SQL::Column,
      @froms = [] of SQL::From,
      @joins = [] of SQL::Join,
      @wheres = [] of Clear::Expression::Node,
      @havings = [] of Clear::Expression::Node,
      @windows = [] of {String, String},
      @group_bys = [] of SQL::Symbolic,
      @order_bys = [] of Clear::SQL::Query::OrderBy::Record,
      @limit = nil,
      @offset = nil,
      @lock = nil,
      @before_query_triggers = [] of -> Void,
      @tags = {} of String => Clear::SQL::Any,
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
        o = [] of T

        fetch(fetch_all: false) do |hash|
          o << T.factory.build(hash, persisted: true, fetch_columns: fetch_columns, cache: @cache)
        end

        o.each { |it| yield(it) }
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
    def count(type : X.class = Int64) forall X
      cr = @cached_result
      return X.new(cr.size) unless cr.nil?

      super(type)
    end

    # Create an array from the query.
    def to_a(fetch_columns = false) : Array(T)
      cr = @cached_result

      return cr if cr

      o = [] of T
      each(fetch_columns: fetch_columns) { |m| o << m }
      o
    end

    # Basically a custom way to write `OFFSET x LIMIT 1`
    def [](off, fetch_columns = false) : T
      self[off, fetch_columns]?.not_nil!
    end

    # Basically a custom way to write `OFFSET x LIMIT 1`
    def []?(off, fetch_columns = false) : T?
      self.offset(off).first(fetch_columns)
    end

    # Get a range of models
    def [](range : Range(Int64), fetch_columns = false) : Array(T)
      self[range, fetch_columns]?.not_nil
    end

    # Get a range of models
    def []?(range : Range(Int64), fetch_columns = false) : Array(T)
      self.offset(range.start).limit(range.end - range.start).to_a(fetch_columns)
    end

    # A convenient way to write `where{ condition }.first`
    def find(fetch_columns, &block) : T?
      x = Clear::Expression.ensure_node!(with Clear::Expression.new yield)
      where(x).first(fetch_columns)
    end

    # A convenient way to write `where({any_column: "any_value"}).first`
    def find(tuple : NamedTuple, fetch_columns = false) : T?
      where(tuple).first(fetch_columns)
    end

    # A convenient way to write `where({any_column: "any_value"}).first!`
    def find!(fetch_columns = false, &block) : T
      x = Clear::Expression.ensure_node!(with Clear::Expression.new yield)
      where(x).first!(fetch_columns)
    end

    # A convenient way to write `where{ condition }.first!`
    def find!(tuple : NamedTuple, fetch_columns = false) : T
      where(tuple).first(fetch_columns).not_nil!
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
    def first!(fetch_columns = false) : T
      first(fetch_columns).not_nil!
    end

    # Get the first row from the collection query.
    # if not found, return `nil`
    def first(fetch_columns = false) : T?
      order_by(Clear::SQL.escape("#{T.pkey}"), "ASC") unless T.pkey.nil? || order_bys.any?

      limit(1).fetch do |hash|
        return T.factory.build(hash, persisted: true, cache: @cache, fetch_columns: fetch_columns)
      end

      return nil
    end

    # Get the last row from the collection query.
    # if not found, return `nil`
    def last!(fetch_columns = false) : T
      last(fetch_columns).not_nil!
    end

    protected def join_impl(name, type, clear_expr)
      # TODO: not sure about that...
      if @columns.empty?
        self.select("#{Clear::SQL.escape(T.table)}.*")
      end

      super(name, type, clear_expr)
    end

    # Get the last row from the collection query.
    # if not found, return `nil`
    def last(fetch_columns = false) : T?
      order_by("#{T.pkey}", "ASC") unless T.pkey.nil? || order_bys.any?

      arr = order_bys.dup # Save current order by

      begin
        new_order = arr.map do |x|
          Clear::SQL::Query::OrderBy::Record.new(x.op, (x.dir == :asc ? :desc : :asc))
        end

        clear_order_bys.order_by(new_order)

        limit(1).fetch do |hash|
          return T.factory.build(hash, persisted: true, cache: @cache, fetch_columns: fetch_columns)
        end

        return nil
      ensure
        # reset the order by in case we want to reuse the query
        clear_order_bys.order_by(order_bys)
      end
    end
  end
end
