Clear provide hook on events over the objects. Events currently supported are `save`, `validate`, `delete`. `create` and `update` will be added in a near future (open an issue if you need it ASAP 😉).

## Defining a hook

```crystal
class MyModel
  include Clear::Model

  before(:validate) do |m|
    m = m.as(self) # This is mandatory, as m is Clear::Model before.
    puts "Before validation of #{m.inspect}"
  end

  after(:validate) do |m|
    m = m.as(self)
    puts "After validation of #{m.inspect}"
  end
end
```

You can define as many hooks as you want.

Hook can be useful to trigger jobs (e.g. send an email?) after specific action taken for example.

Below for example the implementation of the timestamps columns:

```crystal
before(:validate) do |model|
  model = model.as(self)

  unless model.persisted?
    now = Time.now
    model.created_at = now
    model.updated_at = now
  end
end

after(:validate) do |model|
  model = model.as(self)

  # In the case the updated_at has been changed, we do not override.
  # It happens on first insert, in the before validation setup.
  if model.changed? && !model.updated_at_column.changed?
    model.updated_at = Time.now
  end
end
```

## Hook order

The hooks are called in this order:

| order |
| --- |
| before save |
| before validate |
|  ... call validation ... |
| after validate |
| ... call save method ... |
| after save |

- For before hooks, they are called in reverse order of definition (newer first).
- For after hooks, they are called in order of definition.