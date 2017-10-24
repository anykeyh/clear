# Clear

This is an attempt to recreate an ORM for postgresql and crystal from scratch.

Currently just a work in progress

## Architecture

```
+------------------------------------+
| Model | DB Views | Migrations      | < High Levels Tools
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
- [X] Cursor fetching
- [ ] DB Views
- [ ] CTE
