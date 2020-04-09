# BCrypt

We provide helper for storing encrypted password. See example below:

```ruby
class User
  include Clear::Model
  primary_key :id, type: :uuid
  
  column encrypted_password : Crypto::Bcrypt::Password
  
  def password=(x)
    self.encrypted_password = Crypto::Bcrypt::Password.create(x)
  end  
end


# Create a new user with the password
User.create!({password: "helloworld"})

#...

# Get the created user
user = User.query.first

if user.encrypted_password.verify("thisisfalse") # < false
  #...
end

```

