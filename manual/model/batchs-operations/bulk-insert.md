# Bulk insert & delete

You can insert multiple models at the same time \(using just one `INSERT` query\) using the `Collection#import` method:

```ruby
u = User.new({id: 1, first_name: "x"})
u2 = User.new({id: 2, first_name: "y"})
u3 = User.new({id: 3, first_name: "z"})

o = User.import([u, u2, u3])
```

{% hint style="warning" %}
Only non-persisted valid models can be inserted. Any validation failure in the model list will throw an exception and revert the whole process.
{% endhint %}

`Collection#import` allows the passing optional block to refine he insert query built:

```ruby
User.import([u, u2, u3]) do |request| 
  request.on_conflict("(id)").do_update { |upd|
    upd.set("id = NULL")
       .where { users.id == excluded.id }
  }
end
```

