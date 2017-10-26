# Clear

This is an attempt to recreate a fully functional and elegant
Lightweight API Framework + Dense ORM for Crystal, from scratch.

Nothing ambitious at all !

## Key features

- A powerful ORM for PostgreSQL database. No other database are planned yet,
 thus to allow Clear to use the full potential of Postgres.
- A controller system for JSON APIs.
- Assets distribution (html, javascript, images, css).
- Tooling for generating backbone of your application
- Documentation to use the framework.
- Documentation to enhance the framework (plugins).

The idea is to use Clear in backend, and View / React frontend.

*Currently just a work in progress.*

( But the ORM is in good way now! :) )

## Architecture

```
+------------------------------------+
|           THE ORM STACK            +
+------------------------------------+
|  Model | DB Views | Migrations     | < High Level Tools
+---------------+--------------------+
|  Field | Validation | Converters   | < Mapping system
+---------------+--------------------+
|  Clear::SQL   | Clear::Expression  | < Low Level SQL Builder
+------------------------------------+
|  Crystal DB   | Crystal PG         | < Low Level connection
+------------------------------------+
```

The ORM is freely inspired by Sequel and ActiveRecord.
It offers advanced features for Postgres (see Roadmap)

## Roadmap

ORM:

- [X] Validation
- [X] Hook callback
- [X] Field mapping
- [X] Basic SQL: Select/Insert/Update/Delete
- [X] Cursored fetching
- [X] Debug Queries & Pretty Print (sort of)
- [X] Scope
- [X] Locks
- [ ] Having clause
- [ ] CTE
- [ ] All logic of transaction, update, saving...
- [ ] DB Views
- [ ] Caching for N+1 Queries
- [ ] Model joins query
- [ ] Migrations
- [ ] Filling this checklist and drink a beer