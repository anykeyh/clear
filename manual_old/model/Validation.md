## Few words about the presence validator
By default, Clear handle `presence` validation through the `Nilable` type.

Therefore:
- `column x : String` is assumed to be present
- `column x : String?` can be nilable (and NULL in the database)
- `column x : String, presence: false` will assume the value cannot be NULL in the database (e.g. there's a default value) but creating an object without it will not trigger the presence error.

## Saving your data

Clear offers four methods for checking validations: `valid?`, `valid!`, `save` and `save!`

- `valid?` check whether the model is valid. If not, `errors` will not be empty
- `valid!` check if the model is valid or throw exception. Return the model. Usefully for fail-fast code:
```crystal
  my_model.valid!.delete #Why would you delete a model which is valid btw? :-)
```
- `save` will try to insert or update the model. Return `true` if the model has been saved, an `false` otherwise. If `false`, `model.errors` will not be empty.
- `save!` will try to insert or update the model. Raise an exception if validation failed.

## `errors` and `errors?`

Whenever the validation fail, your model will retrieve the different errors into the `errors` field.

`errors` is just an array of record, with `reason : String` and `column : String?`

```crystal
  unless model.save
    puts "Some fields prevent your model to be saved:"
    errors.each do |error|
      puts [error.column, error.reason].compact.join(": ")
    end
  end
```

## Other validators

For simplicity, each of your model implements the method `validate` without body.
You can then create your own validators:

```crystal
# ... in your model
column age : Int32

def validate
  add_error("age", "must be greater than 18") if age < 18
end
```

There's however a catch: You will be in trouble when `age` is not defined (e.g. the field has not been selected). Let's imagine this code:

```crystal
  class User
    include Clear::Model

    column id : Int32, primary:  true, presence: false
    column age : Int32
    column first_name : String
    column last_name : String

    def validate
      # The code below would not work properly in all case, sadly.
      add_error("age", "must be greater than 18") if age < 18
    end
  end

  User.query.select("first_name", "last_name").each do |user|
    user.last_name = user.last_name.uppercase
    user.save!
  end
```

This code will fail, as the query is not fetching `age`. In the condition, calling `age` will throw an exception, telling you than you cannot access it since it's undefined.

To get ride of that, usually validation code must be encapsulated into `on_presence` macro:

```crystal
def validate
  on_presence(age) do
    add_error("age", "must be greater than 18") if age < 18
  end
end
```

Another way to do it would be to use the `age_column` helper method:

```crystal
def validate
  on_presence(age) do
    if age_column.defined? && rating_column.defined?
      add_error("age", "must be greater than 18") if age < 18 && rating == "mature"
    end
  end
end
```

### Ensure than

the `ensure_that` helpers provide fast way to validate a field:

```crystal
def validate
   ensure_that age, "must be greater than 18", &.>(18)
end
```

With the rating column, you can write:

```crystal
def validate
  on_presence(rating){ ensure_that(age, "must be greater than 18"){ |x| x > 18 && rating == "mature"  } }
end
```

Final tips about `on_presence`: it can be used outside of validation.

```ecr
<div class="person">
  <% user.on_presence(first_name, last_name) do %>
    <%= user.full_name %>
  <% end %>
</div>
```