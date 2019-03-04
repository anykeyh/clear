Some useful functionalities are present in each model:

## persisted?

The `persisted?` method allows you to test if a model has been saved in the database or not:

```crystal
m = MyModel.new
m.persisted? #false
m.save!
m.persisted? #true
m.delete
m.persisted? #false
```

## readonly?

Model can be flagged as readonly. They will trigger an error on update/save:

```crystal
class MyModel
  include Clear::Model
  #...
  def readonly?
    true
  end
end
```

## columns

For each column defined, a second property `[column_name]_column` is created. This allow you to check the current status of the column:

```crystal
class MyModel
  column name : String 
end

m = MyModel.new({name: "test"})
m.name_column.defined? #Return true, because defined in the construction.
m.save!
m.name_column.changed? #return false
m.changed? #false
m.name = "test2"
m.changed? #true
m.name_column.changed? #return true
m.name_column.old_value #return "test"
m.name_column.revert #return to "test"
m.changed? #false
```

| function | |
| --- | --- |
| `defined?` | Check if the value has been defined at least once. Note than `nil` in case of nullable column can is a defined value ! |
| `changed?` | Check if the column has been changed since last save |
| `old_value` | Return the old value of the column, or `UNDEFINED` if not changed |
| `revert` | Revert the column to old value. If no old value, return the column into `UNDEFINED` state |
| `nilable?` | Check whether the column can be nil |
| `value` | Try to get the value of the column. If the column is UNDEFINED, throw an exception. |
| `value(default)` | Try to get the value of the column. If the column is UNDEFINED, return default |
| `clear` | Set the column as UNDEFINED |
| `dirty!` | Flag the column as dirty (has been changed) |
| `clear_change_flag` | Inverse of dirty, tell Clear the column didn't changed |
| `failed_to_be_present?` | Return true if the column must be present and is not. |

## to_h and to_update_h

Crystal offers two methods to access to the current fields of the model:

- `to_h` return a hash version of the columns of the model
- `to_update_h` return a curated hash version of only the changed columns of the model