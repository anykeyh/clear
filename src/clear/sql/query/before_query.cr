module Clear::SQL::Query::BeforeQuery
  macro included
    @before_query_triggers : Array(-> Void)

    def before_query(&block : -> Void)
      @before_query_triggers << block
    end

    def trigger_before_query
      @before_query_triggers.each { |bq| bq.call }
      @before_query_triggers.clear
    end
  end
end
