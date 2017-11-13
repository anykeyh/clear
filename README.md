# Clear

Clear ORM is an ORM built on top of PostgreSQL.
There's no will to make it multi-database at all. Thus to allow it to offer
more functionality than other ORM around.

And about functionality, Clear is definitely on top:

- Expressive where query building (like Sequel!)
- N+1 query caching
- Colored request outputed in the log on debug level ! :-)
- CTE, locks, cursors and other advanced PG features are packed in !
- Migration system with integrated PostgreSQL subtilities (e.g. Foreign Key)
- Automatic presence validator through the columns declaration: Using `Type?`
  notation tell Clear that your column doesn't need to be present
- Mostly based on modules and not inheritance: Plug in your project and play!
- Customizable fields converter ("serializer") DB <-> Crystal
- Native integration of different PG structures (Thank's to PG gem !)

Now you get our attention, well, the bad part is it's still a work in progress.
Some basic and advanced features are in, others are just in my head.
Others are just in the process "ok I'm gonna think about it later".


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
- [X] Debug Queries & Pretty Print
- [X] Scope
- [X] Locks
- [ ] Relations => Done `belongs_to`, `has` and `has_many`, in progress on `has_many_through`
- [ ] Having clause
- [ ] CTE
- [ ] All logic of transaction, update, saving...
- [ ] DB Views
- [ ] Caching for N+1 Queries => Done for `belongs_to`!
- [ ] Model joins query
- [X] Migrations
- [ ] crclr tool
- [ ] Handling of compound primary key + CitusDB Support
- [ ] Filling this checklist and drink a beer

## Licensing

This shard is provided under the MIT license.