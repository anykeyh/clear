require "../sql/select_query"

module Clear::Model
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

    def count : Int64
      self.clear_select.select("COUNT(*)").scalar(Int64)
    end

    def max(field, x : T.class) forall T
      self.clear_select.select("MAX(#{field})").scalar.as(T)
    end

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
