# Clear

Clear ORM is currently in development by myself ( github: _anykeyh_ ).
The goal is to provide an advanced ORM for postgreSQL.

Instead of working on adapter for differents database, I wanted to offer the
maximum features for a specific platform.

It's not every day we chose a database layout, and there's few reasons for you
to change your database during the development cycle (at least, from SQL to SQL).

Postgres offers a lot of features in a very performant engine, and seems suitable
for large projects in Crystal.

And here you have ! The ORM made for Postgres and Crystal, simple to use, full
of ideas stolen to ActiveRecord or Sequel :-).

## Architecture

```text
+---------------------------------------------+
|              Clear                          +
+---------------------------------------------+
|  Model | DB Views | Migrations | crclr CLI  | < High Level Tools
+---------------+-----------------------------+
|  Field | Validation | Converters            | < Mapping system
+---------------+-----------------------------+
|  Clear::SQL   | Clear::Expression           | < Low Level SQL Builder
+---------------------------------------------+
|  Crystal DB   | Crystal PG                  | < Low Level connection
+---------------------------------------------+
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
- [X] Migrations
- [ ] crclr tool
- [ ] Handling of compound primary key + CitusDB Support
- [ ] Filling this checklist and drink a beer

## Licensing

This shard is provided under the MIT license.