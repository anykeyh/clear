# v0.1.3alpha


## Breaking changes

- Renaming of column `column` attribute to `column_name` in `column` method helper
- Renaming of `field` by `column` in validation `Error` record
- Renaming of `Clear::Util.func` to `Clear::Util.lambda`

## Bugfixes

- Fix issue with delete if the primary key is not `id`
- Add watchdog to disallow inclusion of `Clear::Model` on struct objects, which
  is not intended to work

## New features

- Bundle with a binary `clear-cli`. Allow you to scaffold projects easily !
- Add CHANGELOG.md file !
- Add specs for `find_or_create` function. Fix issue #XXX
- `model.valid!` return itself and can be chained