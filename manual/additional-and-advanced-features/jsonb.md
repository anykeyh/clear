# JSONB

Clear offers JSONB functions through `Clear::SQL::JSONB` helper and the Expression Engine.

JSONB is a great No-SQL mapping under PostgreSQL. It helps you to store value and documents which otherwise would be difficult

Let's imaging a table `events` where you store the events of differents suppliers:

## Postgres limitation and Clear's answer

The main limitation of JSONB is the "simple" syntax is not indexable. For example:

```sql
  SELECT * FROM events WHERE payload->'source'->>'name' = 'Asana'
```

The code above will not use any indexes and will do a sequencial scan over your table.

However, using the `@>` operator and a `gin` index on your column will improve drastically the performances:

```sql
  SELECT * FROM events WHERE payload @> '{"source": {"name": "Asana"}}'
```

Obviously, the second syntax is more complex and error prone. Clear offers leverage and simplicity:

```ruby
  Event.query.where{ payload.jsonb("source.name") == "asana" }
  #  SELECT * FROM events WHERE payload @> '{"source": {"name": "Asana"}}'
```

## Expression Engine

### jsonb

calling `node.jsonb(key)` on expression node will resolve to:

* node-&gt;'key\_elm1'-&gt;'key\_elm...n'

Using equality testing between a jsonb path and a literal will use the indexable notation `@>` :

```ruby
where{ data.jsonb('a.b.c') == 1 }
#output:
# data @> '{"a":{"b":{"c":1}}}'
```

In the case the operation is not indexable \(e.g. the value is variable, operator is not equality...\), Clear will automatically switch back to the arrow `->` notation:

```ruby
where{ data.jsonb('a.b.c') == raw("NOW()") }
# output:
# data->'a'->'b'->'c' = NOW()
```

**Casting**

You can cast the element using `cast` after your expression:

```ruby
where{ data.jsonb("a.b").cast("text") == "o" }
# output:
# data->'a'->'b'::text == 'o'
```

Note: If you cast the `jsonb`, clear will never use `@>` operator

### From path to arrow notation

```ruby
Clear::SQL::JSONB.jsonb_resolve("data", "a.b.c", "text")
# output:
# data->'a'->'b'->'c'::text
```

## Use outside Expression Engine \(`@>` operator\)

```ruby
Clear::SQL::JSONB.jsonb_eq(data, "a.b.c", "value")
#output:
# data @> {"a":{"b":{"c":"value"}}}
```

