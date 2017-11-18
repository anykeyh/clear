module Clear::SQL::Query::Lock
  macro included
    getter lock : String?
  end

  protected def print_lock
    return unless @lock
    @lock
  end

  def with_lock(str : String = "FOR UPDATE")
    @lock = str
    change!
  end
end
