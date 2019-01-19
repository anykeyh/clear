# Enums

Clear offers support of PG enum.

To define an enum, use the `Clear.enum` method:

```ruby
# Define the enum
Clear.enum Gender, "male", "female"
```

This will create a new record called `MyApp::Gender`, which contains the constants `Male` and `Female`.

## Validation, assignation

You can use the new type directly in your model:

```ruby
class User
  include Clear::Model
  #...

  column gender : Gender
end
```

Assignation cannot be made from string, but instead from constants:

```ruby
u = User.new
u.gender = MyApp::Gender::Male
```

List of helpers are present for validation and conversion from/to string:

```ruby
MyApp::Gender.authorized_values # < return ["male", "female"]
MyApp::Gender.all # < return [MyApp::Gender::Male, MyApp::Gender::Female]

MyApp::Gender::Female.to_s # Return "female"

MyApp::Gender.from_string("male") # < return MyApp::Gender::Male
MyApp::Gender.from_string("unknown") # < throw Clear::IllegalEnumValueError

MyApp::Gender.valid?("female") #< Return true
MyApp::Gender.valid?("unknown") #< Return false
```

## Migration

```ruby
class MyMigration1
    include Clear::Migration

    def change(dir)
        create_enum("gender", %w(male female))
    end
end
```

