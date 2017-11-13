require "../sql/select_query"

module Clear::Model
  # The query collection system
  # Every time a collection is created when you call `Model.query`
  # or call any defined scope
  class CollectionBase(T)
    include Clear::SQL::SelectBuilder

    @tags : Hash(String, Clear::SQL::Any)

    # Redefinition of the fields,
    # because of a bug in the compiler (#5281)
    @limit : Int64?
    @offset : Int64?
    @lock : String?

    def initialize(
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
                   @before_query_triggers = [] of -> Void)
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

    def each(fetch_columns = false, &block)
      fetch do |hash|
        yield(T.new(hash, persisted: true, fetch_columns: fetch_columns))
      end
    end

    def each_with_cursor(batch = 1000, fetch_columns = false, &block)
      self.fetch_with_cursor(count: batch) do |hash|
        yield(T.new(hash, persisted: true, fetch_columns: fetch_columns))
      end
    end

    def build : T
      T.new(@tags, persisted: false)
    end

    def build(x : NamedTuple) : T
      T.new(@tags.merge(x.to_h), persisted: false)
    end

    def any?
      self.clear_select.select("1").limit(1).fetch do |h|
        return true
      end

      return false
    end

    def empty?
      not any?
    end

    def count : Int64
      self.clear_select.select("COUNT(*)").scalar(Int64)
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
      out = [] of T
      each(fetch_columns: fetch_columns) { |m| out << m }
      out
    end

    def [](off) : T
      self.[]?(off).not_nil
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

      return r unless r.nil?

      str_hash = {} of String => Clear::SQL::Any

      tuple.map { |k, v| str_hash[k.to_s] = v }
      str_hash.merge!(@tags)

      r = T.new(str_hash)
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
        return T.new(hash, persisted: true)
      end

      return nil
    end
  end
end
