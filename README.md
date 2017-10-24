# Clear

This is an attempt to recreate an ORM for PostgreSQL and Crystal from scratch.

Currently just a work in progress

## Architecture

```
+------------------------------------+
| Model | DB Views | Migrations      | < High Level Tools
+---------------+--------------------+
|  Field | Validation | Converters   | < Mapping system
+---------------+--------------------+
|  Clear::SQL   | Clear::Expression  | < Low Level SQL Builder
+------------------------------------+
|  Crystal DB   | Crystal PG         | < Low Level connection
+------------------------------------+
```

## Roadmap

- [X] Validation
- [X] Hook callback
- [X] Field mapping
- [X] Basic SQL: Select/Insert/Update/Delete
- [X] Cursored fetching
- [X] Debug Queries & Pretty Print (sort of)
- [ ] Model joins query
- [X] Scope
- [ ] Locks
- [ ] Having clause
- [ ] CTE
- [ ] All logic of transaction, update, saving...
- [ ] DB Views
- [ ] Caching for N+1 Queries
- [ ] Migrations
- [ ] Filling this checklist and drink a beer