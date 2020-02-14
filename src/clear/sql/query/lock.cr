module Clear::SQL::Query::Lock
  macro included
    getter lock : String?
  end

  # :nodoc:
  protected def print_lock
    return unless @lock
    @lock
  end

  # remove lock directive.
  def clear_lock
    @lock = nil
    change!
  end

  # You can use lock using `with_lock` method on query collection:
  #
  # ```
  # Clear::SQL.transaction do
  #     # SELECT * FROM users WHERE organization = 'Crystal Lang' FOR UPDATE
  #     User.where(organization: "Crystal Lang").with_lock.each do |user|
  #         # Do something with your users
  #     end
  # end
  # ```
  #
  # `with_lock` offers optional parameters \(default: `"FOR UPDATE"`\), to setup the lock options you want \(ex: `with_lock("FOR UPDATE SKIP LOCKED")`\)
  #
  # See PostgreSQL [deep explanation about locking here](https://www.postgresql.org/docs/current/explicit-locking.html).
  #
  # {% hint style="warning" %}
  # Locking works only in transaction.
  # {% endhint %}
  def with_lock(str : String = "FOR UPDATE")
    @lock = str
    change!
  end
end
