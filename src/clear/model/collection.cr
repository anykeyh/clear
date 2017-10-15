require "../sql/select_query"

module Clear::Model
  class Collection(T) < Clear::SQL::SelectQuery
    def each(&block)
    end

    def to_a : Array(T)
      out = [] of T

      self.to_rs do |rs|
        T.new(rs)
      end
    end

    # Pluck one value
    def pluck(field_name, c : Class(T)) : Array(T) forall T
    end

    def first : T
      T.new(limit(1).offset(0).to_rs)
    end
  end
end
