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
    # because of a bug in the compiler (#5281)
    @limit : Int64?
    @offset : Int64?
    @lock : String?

    @cache : Clear::Model::QueryCache
    @cached_result : Array(T)?

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

    # We can pass a cache to the models which are going to be instantiated
    # This cache is used for relation calling of thoses models
    def cached(cache : Clear::Model::QueryCache)
      @cache = cache
      self
    end

    # we can set the result of this request here.
    def with_cached_result(r : Array(T))
      @cached_result = r
      self
    end

    def clear_cached_result
      @cached_result = nil
      self
    end

    def change!
      # In case we filter this collection, we remove the cache
      clear_cached_result
    end

    # Tags are used for building
    #  from relations
    def tags(x : NamedTuple)
      @tags.merge!(x.to_h)
      self
    end

    def tags(x : Hash(String, X)) forall X
      @tags.merge!(x.to_h)
      self
    end

    def clear_tags
      @tags = {} of String => Clear::SQL::Any
      self
    end

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

    def map(fetch_columns = false, &block : T -> X) : Array(X) forall X
      o = [] of X
      each(fetch_columns) { |mdl| o << block.call(mdl) }
      o
    end

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

    def build : T
      pp @tags
      T.factory.build(@tags, persisted: false)
    end

    def build(x : NamedTuple) : T
      T.factory.build(@tags.merge(x.to_h), persisted: false)
    end

    def any?
      cr = @cached_result

      return cr.any? if cr

      self.clear_select.select("1").limit(1).fetch do |_|
        return true
      end

      return false
    end

    def empty?
      not any?
    end

    def count(what = "*") : Int64
      cr = @cached_result

      return Int64.new(cr.size) if cr

      self.clear_select.select("COUNT(#{what})").scalar(Int64)
    end

    # Call an aggregation function.
    def agg(field, x : T.class) forall T
      self.clear_select.select(field).scalar.as(T)
    end

    {% for x in %w(min max avg) %}
      def {{x.id}}(field, x : T.class) forall T
        agg("{{x.id.upcase}}(#{field})", T)
      end
    {% end %}

    def to_a(fetch_columns = false) : Array(T)
      cr = @cached_result

      return cr if cr

      out = [] of T
      each(fetch_columns: fetch_columns) { |m| out << m }
      out
    end

    def [](off) : T
      self.[]?(off).not_nil!
    end

    def []?(off) : T?
      self.offset(off).first
    end

    def find(&block) : T?
      x = Clear::Expression.to_node(with Clear::Expression.new yield)
      where(x).first
    end

    def find(tuple : NamedTuple) : T?
      where(tuple).first
    end

    def find!(&block) : T
      x = Clear::Expression.to_node(with Clear::Expression.new yield)
      where(x).first!
    end

    def find!(tuple : NamedTuple) : T
      where(tuple).first.not_nil!
    end

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

    def find_or_create(tuple : NamedTuple, &block : T -> Void) : T
      r = find_or_build(tuple, &block)
      r.save
      r
    end

    def first! : T
      first.not_nil!
    end

    def first : T?
      order_by("#{T.pkey} ASC") unless T.pkey.nil?

      limit(1).fetch do |hash|
        return T.factory.build(hash, persisted: true, cache: @cache)
      end

      return nil
    end

    def last! : T
      last.not_nil!
    end

    def last : T?
      order_by("#{T.pkey} DESC")

      limit(1).fetch do |hash|
        return T.factory.build(hash, persisted: true, cache: @cache)
      end

      return nil
    end


  end
end
