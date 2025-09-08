module Clear::SQL::Query::BeforeQuery
  macro included
    @before_query_triggers : Array(-> Nil)

    # A hook to apply some operation just before the query is executed.
    #
    # ```
    # call = 0
    # req = Clear::SQL.select("1").before_query { call += 1 }
    # 10.times { req.execute }
    # pp call # 10
    # ```
    def before_query(&block : -> Nil)
      @before_query_triggers << block
      self
    end

    # :nodoc:
    protected def trigger_before_query
      @before_query_triggers.each &.call
      @before_query_triggers.clear
      self
    end
  end
end
