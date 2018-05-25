# v0.1.3alpha


## Breaking changes

In column method helper:
  - Renaming of column `column` attribute to `column_name`

## Bugfixes

- Fix issue with delete if the primary key is not `id`
- Add watchdog to disallow inclusion of `Clear::Model` on struct objects, which
  is not intended to work

## New features

- Bundle with a binary `clear-cli`. Allow you to scaffold projects easily !
- Add specs for `find_or_create` function.
- Add CHANGELOG.md file !