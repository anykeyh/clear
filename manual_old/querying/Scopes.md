Scope allow you to pack the logic of your filters into easy-to-read helpers:

```crystal
class User
  include Clear::Model
  #...
  scope(admin){ where{admin == true} }
end

User.query.admin.each do |u|
end
```

Scope can be chained during the building of your query, and can have parameters:

```crystal
  # in your model definition
  scope(with_roles){ |*roles| where{ role.in?(roles) } }
  
  User.query.admin.with_roles("publisher", "supplier").each do |u|
    #...
```
