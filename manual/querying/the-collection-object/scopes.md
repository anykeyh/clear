# Scopes

Scope provides elegant way to write commonly used query fragments and improve readability of your code. Scope returns a new collection Collection or taint the current Collection.

Let's get an example:

```ruby
class User
    include Clear::Model

    with_serial_pkey

    column role : String
    column role_level : Int32
    column email : String
    column active : Bool

    scope :with_privileges do |level|
        where{ role.in?(%w(superadmin admin)) | (role_level > level) }
    end
    scope(:active){ where(active: true) }
end

# Later one:
User.with_privileges(3).each do |x|
    puts "Admin #{x.id} - #{x.email}"
end
```

Scope can be easily chained and you can pass argument to them too:

```ruby
User.with_admin_privileges(4).active
```

Scope live both in `Model::Collection` and `Model` code space, meaning you may ignore `Model.query` to start a new Collection but instead go straight to `Model.scope`.

