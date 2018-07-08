module Clear::SQL::Query::BeforeQuery
  macro included
    @before_query_triggers : Array(-> Void)

    # A hook to apply some operation just before the query is executed.
    #
    # ```crystal
    #  call = 0
    #  req = Clear::SQL.select("1").before_query{ call += 1 }
    #  10.times{ req.execute }
    #  pp call # 10
    # ```
    def before_query(&block : -> Void)
      @before_query_triggers << block
    end

    # :nodoc:
    protected def trigger_before_query
      @before_query_triggers.each { |bq| bq.call }
      @before_query_triggers.clear
    end
  end
end
