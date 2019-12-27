By default, Clear models create a primary key of name `id` and type `bigserial`.

## A table with a longserial primary key

This is the default behavior:

```crystal
# in migration
create_table :my_records do |t|
 # Will create an id of type longint, and a serial over it.
end

# in model
class MyRecord
  include Clear::Model

  with_serial_pkey #< will create a column :id of type UInt64
end
```

## A table with a serial primary key

Same than above, but with only 32 bits integer as primary key:

```crystal
# in migration
create_table :my_records, id: :serial do |t|
 # Will create an id of type int, and a serial over it.
end

# in model
class MyRecord
  include Clear::Model

  with_serial_pkey type: :serial #< will create a column :id of type UInt32
end
```

## A table with a serial UUID

Useful for scaling your DB (e.g. using CitusDB), with slight performance impact
on indexation time and space taken by your database.
Note than Clear will perform auto-assignement of a random UUID on first save of a model

```crystal
# in migration
create_table :my_records, id: :uuid do |t|
  # Will create an id of type uuid. No default value is given, but the field is non-nullable and unique
end

# in model
class MyRecord
  include Clear::Model

  with_serial_pkey type: :uuid #< will create a column :id of type UUID
                               #  will assign a random UUID before first save
end
```

## A table with a custom primary key

Sometime you want special primary key, and want to disable the auto-id:

```crystal
# in migration
create_table :my_records, id: false do |t|
  t.column :my_key, :string, primary: true
end

# in model
class MyRecord
  include Clear::Model

  column my_key : String, primary: true
end
```
