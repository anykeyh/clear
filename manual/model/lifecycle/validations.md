# Validations

Validation offers simple way to disable the updating and creation of invalid models to your database.

## Presence validator

The presence validation ensure than a column is not `NULL` inside the database. While we encourage to use the `NOT NULL` feature of PostgreSQL, the presence validator is automatically setup via the typing of the column:

* `column x : String` is assumed to be present
* `column x : String` can be nilable
* `column x : String, presence: false` will assume the value cannot be NULL in the database, while not performing any validation check. This is great for values which have default database set value \(ex: serial, timestamp...\)

## Custom validation

To create a custom validator, just override the `validate` method:

```ruby
class Article
  include Clear::Model

  column name : String
  column description : String

  def validate
    if description_column.present?
        if description.size < 100
          add_error("description", "must contains at least 100 characters")
        end
    end
  end
end
```

{% hint style="warning" %}
Ensure to check presence of your column while validation. In case of semi-fetching where the column would not have been fetched from the database or not setup, the validator will raise an exception otherwise.
{% endhint %}

## Helpers methods

To simplify the writing of validation code, you may want to use `on_presence(field, &block)` or `ensure_than(field, message, &block)` built-in helpers:

```ruby
class Article
  include Clear::Model

  column name : String
  column description : String

  def validate
    ensure_than :description, "must contains at least 100 characters", &.size.<(100)
  end
end
```

The code above will perform exactly like the previous one, while keeping a more compact syntax.

## Error object

Whenever a validation check is failing, an error is created and stored in the model. Error is simply a structure with two fields: `column : String?` and `reason : String`

The list of error can be accessed through `errors` method:

```ruby
a = Article.new
a.content = "Lorem ipsum"

unless a.valid?
  a.errors.each do |err|
    puts "Error on column: #{err.column} => #{err.reason}"
  end
end
```

