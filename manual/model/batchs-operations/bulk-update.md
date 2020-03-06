# Bulk update

## Bulk update

Any simple query can be transformed to `update` query. The new update query will use the `where` clause as parameter for the update.

```ruby
User.query.where(name =~ /[A-Z]/ ).
     to_update.set(name: Clear::SQL.unsafe("LOWERCASE(name)")).execute
```

## Bulk delete

Same apply for DELETE query.

```ruby
User.query.where(name !~ /[A-Z]/ ).
     to_delete.execute
```

{% hint style="warning" %}
Beware: Bulk update and delete do not trigger any model lifecycle hook. Proceed with care.
{% endhint %}

