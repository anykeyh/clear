# has\_one

Has many represents the second counter part of [belongs to](https://clear.gitbook.io/project/model/associations/belongs_to) relation. It assumes the current model is referenced by an object \(or no objects\) of another model.

Usually, it's used when another model optionally extend the current model by composition. A common example is the usage of `User` and `UserInfo`. `UserInfo` is setup after registration and filling of form from the user. An User can then exists without `UserInfo` – this handle all the connection lifecycle – while `UserInfo` will handle all the optional informations about the user.

```ruby
class User
  include Clear::Model

  with_serial_pkey

  has_one user_info : UserInfo
end

class UserInfo
  include Clear::Model

  with_serial_pkey

  belongs_to user : User
end
```

