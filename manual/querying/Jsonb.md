## Jsonb

Clear offers JSONB functions through `Clear::SQL::JSONB` helper and the Expression Engine.

JSONB is a great No-SQL mapping under PostgreSQL. It helps you to store value
and documents which otherwise would be difficult

Let's imaging a table `events` where you store the events of differents suppliers:

### Limitations

The main limitation of JSONB in my opinion is the "simple" syntax is not indexable.
For example:

```sql
  SELECT * FROM events WHERE payload->'source'->>'name' = 'Asana'
```

will not use any indexes and will do a sequencial scan over your table.

However, using the `@>` operator and a `gin` index on your column will improve 
drastically the performances:

```sql
  SELECT * FROM events WHERE payload @> '{"source": {"name": "Asana"}}'
```

Obviously, the second syntax is more complex and error prone. Clear offers leverage
and simplicity:

```crystal
  Event.query.where{ payload.jsonb("source.name") == "asana" }
```

### Expression Engine

### jsonb

calling `node.jsonb(key)` on expression node will resolve to:
- node->'key_elm1'->'key_elm...n'

Using equality testing between a jsonb path and a literal will use the indexable
notation `@>` :

```crystal
where{ data.jsonb('a.b.c') = 1 }
#output:
# data @> '{"a":{"b":{"c":1}}}'
```

#### Casting

You can cast the element using `cast` after your expression:

```crystal
where{ data.jsonb("a.b").cast("text") }
# output:
# data->'a'->'b'::text
```

Note: If you cast the jsonb, clear will never use `@>` operator


### From path to arrow notation

```crystal
Clear::SQL::JSONB.jsonb_resolve("data", "a.b.c", "text")
# output:
# data->'a'->'b'->'c'::text
```

### Check presence of a value in a json (`@>` operator)

```crystal
Clear::SQL::JSONB.jsonb_eq(data, "a.b.c", "value")
#output:
# data @> {"a":{"b":{"c":"value"}}}
```

