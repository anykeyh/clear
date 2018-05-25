# v0.1.3alpha


## Breaking changes

In column method helper:
  - Renaming of column `column` attribute to `column_name`

## Bugfixes

- Fix issue with delete if the primary key is not `id`

## New features

- Add watchdog to disallow inclusion of `Clear::Model` on struct objects (which can cause unexpected behaviors on copy...)
- Add specs for `find_or_create` function.
- Finalization of the code for `clear-cli`. Allow you to scaffold projects
- Add CHANGELOG.md file !