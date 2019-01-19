## `find` & `first`

```crystal
# Select model by primary key:
mdl = MyModel.query.find(1) # < mdl is MyModel | Nil
mdl = MyModel.query.find!(1) # < mdl is MyModel. Raise error if not found.

# Select model by specific field:
mdl = MyModel.query.find!({name: "model1"})

# Select model by where expression:
mdl = MyModel.query.find!{ name == "model1" }

# find is an alias to write first:
mdl = MyModel.query.where{id: 1}.first
```

## first_or_create, first_or_build

This allow you to create a model if not found:

```crystal
me = User.query.where({first_name: "Yacine", last_name: "Petitprez"}).first_or_create do |u|
  u.passion = "development" #< The bloc will be triggered only if the model is new.
end

me.first_name # Yacine
```

Note 1: Clear offers the `first_or_build` method which doesn't insert the model after execution of the block.

Note 2: Clear currently support assignment on creation only if you use the named tuple on where clause. Usage of `where` with string or expression engine will not automatically fill the constraints