## Enum

Clear offers full support of postgres enum strings.

### Example

Let's say you need to define an enum for genders:

```crystal
# Define the enum
Clear.enum MyApp::Gender, "male", "female" #, ...
```

In migration, we tell Postgres about the enum:

```crystal
create_enum :gender, MyApp::Gender #< Create the new type `gender` in the database

create_table :users do |t|
  # ...
  t.gender "gender" #< first `gender` is the type of column, while second is the name of the column
end
```

Finally in your model, simply add the enum as column:

```crystal
class User
  include Clear::Model
  #...

  column gender : MyApp::Gender
end
```

Now, you can assign the enum:

```crystal
u = User.new
u.gender = MyApp::Gender::Male
```

You can dynamically check and build the enumeration values:

```crystal
MyApp::Gender.authorized_values # < return ["male", "female"]
MyApp::Gender.all # < return [MyApp::Gender::Male, MyApp::Gender::Female]

MyApp::Gender.from_string("male") # < return MyApp::Gender::Male
MyApp::Gender.from_string("unknown") # < throw Clear::IllegalEnumValueError

MyApp::Gender.valid?("female") #< Return true
MyApp::Gender.valid?("unknown") #< Return false
```

However, you cannot write:

```crystal
u = User.new
u.gender = "male"
```