# Locks

### Model lock

You can use lock using `with_lock` method on query collection:

```ruby
Clear::SQL.transaction do
    # SELECT * FROM users WHERE organization = 'Crystal Lang' FOR UPDATE
    User.where(organization: "Crystal Lang").with_lock.each do |user|
        # Do something with your users
    end
end
```

`with_lock` offers optional parameters \(default: `"FOR UPDATE"`\), to setup the lock options you want \(ex: `with_lock("FOR UPDATE SKIP LOCKED")`\)

See PostgreSQL [deep explanation about locking here](https://www.postgresql.org/docs/current/explicit-locking.html).

{% hint style="warning" %}
Lock work only inside transaction. Without transaction block, the call might fail.
{% endhint %}



