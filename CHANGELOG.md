# master/HEAD (v0.6)

## Features

- [EXPERIMENTAL] Add `<<` operation on collection which comes from `has_many` and `has_many through:`

# v0.5: Merry christmas 🎄

## Features

### Connection pool

Clear wasn't fiber-proof since it lacks of connection pool system. It's now fixed, the connection pooling is done
completely transparently without any boilerplate on your application side.

Each fiber may require a specific connection; then the connection is binded to the fiber. In the case of `transaction`
and `with_savepoint`, the connection is kept until the end of the block happens.
On the case of normal execution or cursors, we store the connection until the execution is done.

The connection pool is using Channel so in case of pool shortage, the fiber requesting the connection is put in
waiting state.

This is a huge step forward:
- Clear can be used in framework with `spawn`-based server and other event machine system.
- I'll work on performance improvement or other subtilities in some specific cases, where multiple requests can be
  parallelized over different connections.

## Bug fixes
- Fix #53
- Update ameba to latest version
- Large refactoring on relations
- Many bugfixes

# v0.4

## Features
- Improved Model build/create methods, allowing to pass arguments instead of NamedTuple
- #48 Add `lateral join` feature:
  ```crystal
    Model.query.left_join("other_model", lateral: true){ model.id == other_model.model_id }
  ```
- #35 Add methods `import` over collection, to be able to insert multiple objects with one query:
  ```crystal
    user_array = 10.times.map{ |x| User.new(name: "user#{x}")  }
    Model.import(user_array)
  ```
- #42 Add support of `ON CONFLICT` both in `Insert` and `Model#save`
  ```crystal
    u = User.new(id: 1, first_name: "me")
    u.save! &.on_conflict("(id)").do_update(&.set("first_name = excluded.first_name").where { model_users.id == excluded.id })
  ```
  - Note: Method `Model#import` explained above can use the same syntax to resolve conflict.
  This will helps to use Clear for import, CSV and batch processing.
- #26 Add `to_json` supports to model. Please note that some core lib and shards `pg` objects got
  extended to allow this support:
  - By default, undefined fields are not exported. To export all columns even thoses which are not fetched in SQL, use `full: true`. For example:
  ```
    User.query.first!.to_json # => {"id":1, "first_name":"Louis", "last_name": "XVI"}
    User.query.select("id, first_name").first!.to_json # => {"id":1, "first_name":"Louis"}
    User.query.select("id, first_name").first!.to_json(full: true) # => {"id":1, "first_name":"Louis", "last_name": null}
  ```

## Bug fixes
- Escaping table, columns and schema name to allow Clear to works on any SQL restricted names.
  - This is very demanding work as it turns out table and columns naming are used everywhere
    in the ORM. Please give me feedback in case of any issues !
- Fix #31, #36, #38, #37
- Fix issue with polymorphic table

## Breaking changes
- Renaming `insert` method on `InsertQuery` to `values`, making API more elegant.
- Usage of `var`  in Expression engine has been changed and is now different from raw:
  - `var` provide simple way to construct `[schema].table.field` structure,
  with escaped table, field and schema keywords.
  - `raw` works as usual, printing the raw string fragment to you condition.
  - Therefore:
    ```crystal
      where{ var("a.b") == 1 } # Wrong now! => WHERE "a.b" = 1
      # Must be changed by:
      where{ var("a", "b") == 1 } # OR
      where{ raw("a.b") }
    ```
    TL;DR, if you currently use `var` function, please use `raw` instead from now.
- Revamping the converter system, allowing to work seemlessly with complexes types like Union and Generic
  - Documentation will follow soon.

# v0.3.1

Basically a transition version, to support Crystal 0.27. Some of the features of 0.4 were deployed already in 0.3.1. See above for the new features/changes.

# v0.3

## Features
- Add support to pg Enum
- Add support for UUID primary key, with uuid autogeneration
- Add support for BCrypt fields, like passwords
- Finalization of CLI !
- Add `Clear.seed(&block)`
  `Clear.seed` goes in pair with `bin/clear migrate seed` which will call the seed blocks.
- Add possibility to use has_many through without having to declare the model doing the relation
  For example, if A belongs to B, B belongs to C, then A has_many C through B. You can
  perform this now without declaring any class for B; see the guide about relations for
  more informations.
- Add error messages so cool you want your code to crash 😉

## Bug fixes
- Fix #23 bug with `has_many through:` and select
- Add support for `DISTINCT ON` feature.
- Array(String), Array(Int64) columns type are working now works

## Breaking changes
- `Model#save` on read only model do not throw exception anymore but return false (save! still throw error)
- `with_serial_pkey` use Int32 (type `:serial`) and Int64 (type `:longserial`) pkey instead of UInt32 and UInt64. This would prevent issue with default `belongs_to` behavior and simplify static number assignation.

# v0.2

## Breaking changes
- Migration to crystal 0.25.

## Bug fixes
- Fix #13 Calling count on paginated query.
- Fix #17 and implement `group_by` method.
- Fix #18 ambiguous column with joins.

## Features
- Full Text Searchable module using tsvector to simplify... full text search !
- SQL Builder can now be used with model collection as subqueries.
- Add methods for pagination (PR #16, thanks @jwoertink)
- Add multi-connections system (PR #18, thanks @russ)
- Add JSONB helpers in expression engine. Check the manual !
- Migrating the wiki to the sources of the project, to make easy to have PR for
  updating the documentation !
- Add range support for `Sql::Node#in?` method:
  ```crystal
    last_week_users = User.query.where{ created_at.in?(7.day.ago..Time.now) }.count
  ```
- Refactoring of the nodes and clause of the SQL builder, avoiding array instantiation (usage of tuple instead) and starting to use Node as much as possible to build clauses.
- Add `Clear::Expression.unsafe` which does exactly what it says:
  ```crystal
  where("a = :a AND b = :b", {a: "test", b: Clear::Expression.unsafe("NOW()") })
  # -> WHERE a = 'test' AND b = NOW()
  ```

# v0.1.3alpha


## Breaking changes

- Renaming of column `column` attribute to `column_name` in `column` method helper
- Renaming of `field` by `column` in validation `Error` record
- Renaming of `Clear::Util.func` to `Clear::Util.lambda`
- `order_by` don't allow full string anymore, and will cause error in case you put string.

## Bugfixes

- Patching segfault caused by weird architecture choice of mine over the `pkey` method.
- Fix issue with delete if the primary key is not `id`
- Add watchdog to disallow inclusion of `Clear::Model` on struct objects, which
  is not intended to work.
- Issue #8: `find_or_create` and generally update without any field failed to generate good SQL.
- Issue with `belongs_to` assignment fixed.
- Fix error message when a query fail to compile, giving better insights for the developer.
- Issue #12: Fix `Collection(Model)#last`.
- Allow `fetch_columns` on last, first etc...

## Small features

- Add CHANGELOG.md file !
- `model.valid!` return itself and can be chained
- Issue #10: `scope` allow block with multiple arguments.
- Add tuple support for `in?` method in Expression Engine.

## Big features

- Creation of the Wiki manual ! Check it out !

### Polymorphism (experimental)

You can now use polymorph models with Clear !

Here for example:

```crystal

abstract class Document
  include Clear::Model

  column content : String

  self.table = "documents"

  polymorphic ImageDocument, TextDocument

  abstract def to_html : String
end

class ImageDocument < Document
  column url : String

  def to_html
    <<-HTML
      <img src='#{url}' alt='#{content}'></img>
    HTML
  end
end

class TextDocument < Document
  def to_html
    <<-HTML
      <p>#{content}</p>
    HTML
  end

end

#...

# Create a new document
ImageDocument.create({url: "http://example.com/url/to/img.jpg"})

# Use the abstract class to query !
Document.query.all.each do |document|
  puts document.to_html
end

```
