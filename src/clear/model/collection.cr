require "../sql/select_query"

module Clear::Model
  class CollectionBase(T)
    include Clear::SQL::SelectBuilder

    def each(&block)
      self.each do |hash|
        yield(T.new(hash))
      end
    end

    def each_with_cursor(batch = 1000, &block)
      self.to_rs_cursor(count: batch) do |hash|
        yield(T.new(hash))
      end
    end

    def to_a : Array(T)
      out = [] of T
      each { |m| out << m }
      out
    end

    # Pluck one specific value
    # def pluck(fields : NamedTuple(*U)) : Array(Hash(String, U)) forall U

    # end

    def first : T
      limit(1).each do |hash|
        return T.new(hash)
      end

      raise "Not Found"
    end
  end
end
