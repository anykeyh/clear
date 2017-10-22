require "../sql/select_query"

module Clear::Model
  class CollectionBase(T)
    include Clear::SQL::SelectBuilder

    def each(&block)
      self.to_rs do |hash|
        yield(T.new(hash))
      end
    end

    def each_with_cursor(batch = 1000, &block)
      self.to_rs_cursor(count: batch) do |hash|
        yield(T.new(hash))
      end
    end

    # def self.each(rs : ::DB::ResultSet)
    #   objs = Array(self).new
    #   rs.each do
    #     objs << self.new(rs)
    #   end
    #   objs
    # ensure
    #   rs.close
    # end

    def to_a : Array(T)
    end

    # Pluck one value
    def pluck(field_name, c : Class(T)) : Array(T) forall T
    end

    def first : T
      limit(1).to_rs do |hash|
        return T.new(hash)
      end

      raise "Not Found"
    end
  end
end
