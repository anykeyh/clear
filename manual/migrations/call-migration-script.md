# Call migration script

## Call migration script

Clear offers a migration system. Migration allow you to handle state update of your database.

Migration is a list of change going through a direction, up \(commit changes\) or down \(rollback changes\).

In clear, a migration is defined like this:

```ruby
class MyMigration1
  include Clear::Migration

  def change(direction)
    direction.up do
      #do something on commit
    end

    direction.down do
      #do something on rollback
    end
  end
end
```

## Executing custom SQL

The basic usage is to execute your own SQL \(e.g. CREATE TABLE, ALTER, GRANT etc...\).

To do it, just call `execute` into your direction block.

### Example

```ruby
class MyMigration1
  include Clear::Migration

  def change(direction)
    direction.up do
      execute("CREATE TABLE my_models...")
    end

    direction.down do
      execute("DROP TABLE my_models")
    end
  end
end
```

## Built-in helpers

Clear offers helpers for simplify declaring your migration

### Creating a table

Clear provides DSL looking like ActiveRecord for creating a table.

```ruby
create_table(:users) do |t|
    t.column :first_name, :string, index: true
    t.column :last_name, :string, unique: true

    # Will create a "user_info_id" field of type longint with a foreign key constraint
    # This reference can be null, and if the user_info is deleted then the user is deleted too.
    t.references to: "user_infos", name: "user_info_id", on_delete: "cascade", null: true

    # Example of creating index on full name
    t.index "lower(first_name || ' ' || last_name)", using: :btree

    t.timestamps
end
```

## Migration ordering

Migration should be ordered by a number. This number can be written in different way:

* In case of mixing multiple classes into the same file, you can append the number at the end of the class name:

```ruby
class Migration1
  include Clear::Migration

  def change(dir)
    #...
  end
end
```

If you're using one file per migration, you can prepend the ordering number at the start of the file name:

```text
1234_migration.cr
```

Finally, if you feel more rock'n'roll and build a complex dynamic migration system on top of Clear, you can override the uid method:

```ruby
class Migration1
  include Clear::Migration

  def uid
    123_i64 #Number must be a signed 64bits integer !
  end

  def change(dir)
    #...
  end
end
```

## Calling your migration

Clear will offers soon a CLI; meanwhile, you can call migration update using methods in the Migration Manager:

```ruby
# Activate all the migrations. Will call change with up direction for each down migrations
Clear::Migration::Manager.instance.apply_all
```

```ruby
# Go to a specific migration. All migration with a number above than the version number will be downed if not yet down.
# All migrations with a version number below will be activated if not yet up.
Clear::Migration::Manager.instance.apply_to(version_number)
```

