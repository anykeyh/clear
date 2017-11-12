require "../sql/select_query"

module Clear::Model
  # The query collection system
  # Every time a collection is created when you call `Model.query`
  # or call any defined scope
  class CollectionBase(T)
    include Clear::SQL::SelectBuilder

    def each(fetch_columns = false, &block)
      fetch do |hash|
        yield(T.new(hash, fetch_columns: fetch_columns))
      end
    end

    def each_with_cursor(batch = 1000, fetch_columns = false, &block)
      self.fetch_with_cursor(count: batch) do |hash|
        yield(T.new(hash, fetch_columns: fetch_columns))
      end
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

    def find(&block) : T
      x = Clear::Expression.to_node(with Clear::Expression.new yield)
      where(x).first!
    end

    # Pluck one specific value
    # def pluck(fields : NamedTuple(*U)) : Array(Hash(String, U)) forall U

    # end

    def first! : T
      first.not_nil!
    end

    def first : T?
      limit(1).fetch do |hash|
        return T.new(hash)
      end

      return nil
    end
  end
end
