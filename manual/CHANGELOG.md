# v0.9

v0.9 is a big overhaul from the shard. It simplifies a lot of the internal code,
add tons of specs and focus on things like more understandable error on compile time.

Note of warning: This version break tons of stuff.

## Breaking changes

- `Clear::Migration::Direction` is now an enum instead of a struct.
- where and having clauses use splat and named tuple always. This is breaking change.
  - Before you had to do:

  ```crystal
    where("a = ?", [1])
  ```

  Now you can do much more easy:

  ```crystal
    where("a = ?", 1)
  ```

  Same apply for the named parameters version:

  ```crystal
    # Instead of
    where("a = :a", { a: 1 } )
    # Do
    where("a = :a", a: 1)
  ```


## Features

- `Collection#add_operation` has been renamed to `Collection#append_operation`
- Add `Clear::SQL.after_commit` method

Register a callback function which will be fired once when SQL `COMMIT`
operation is called

This can be used for example to send email, or perform others tasks
when you want to be sure the data is secured in the database.

```crystal
  transaction do
    @user = User.find(1)
    @user.subscribe!
    Clear::SQL.after_commit{ Email.deliver(ConfirmationMail.new(@user)) }
  end
```

In case the transaction fail and eventually rollback, the code won't be called.

Same method exists now on the model level, using before and after hooks:

```crystal
  class User
    include Clear::Model

    after(:commit){ |mdl| WelcomeEmail.new(mdl.as(User)).deliver_now }
  end
```

Note: `before(:commit)` and `after(:commit)` are both called after the transaction has been commited.
      Before hook always call before after hook.

- Add `Clear.json_serializable_converter(CustomType)`

This macro help setting a converter transparently for any `CustomType`.
Your `CustomType` must be `JSON::Serializable`, and the database column
must be of type `jsonb`, `json` or `text`.

```crystal
  class Color
    include JSON::Serializable

    @[JSON::Field]; property r: Int8
    @[JSON::Field]; property g: Int8
    @[JSON::Field]; property b: Int8
    @[JSON::Field]; property a: Int8
  end

  Clear.json_serializable_converter(Color)

  # Now you can use Color in your models:

  class MyModel
    include Clear::Model

    column color : Color
  end
```

- Add `jsonb().contains?(...)` method

This allow usage of Postgres `?` operator over `jsonb` fields:

```crystal
  # SELECT * FROM actors WHERE "jsonb_column"->'movies' ? 'Top Gun' LIMIT 1;
  Actor.query.where{ var("jsonb_column").jsonb("movies").contains?("Top Gun") }.first!.name # << Tom Cruise
```

- Add `SelectQuery#reverse_order_by` method

A convenient method to reverse all the order by clauses,
turning each `ASC` to `DESC` direction, and each `NULLS FIRST` to `NULLS LAST`


# v0.8

## Features

- Add `or_where` clause

This provide a way to chain where clause with `or` operator instead of `and`:

```crystal
query.where{ a == b }.or_where{ b == c } # WHERE (A = B) OR (b = C)
query.where{ a == b }.where{ c == d}.or_where{ a == nil } # WHERE ( A=B AND C=D ) OR A IS NULL
```

- Add `raw` method into `Clear::SQL` module.

This provide a fast way to create SQL fragment while escaping items, both with `?` and `:key` system:

```crystal
query = Mode.query.select( Clear::SQL.raw("CASE WHEN x=:x THEN 1 ELSE 0 END as check", x: "blabla") )
query = Mode.query.select( Clear::SQL.raw("CASE WHEN x=? THEN 1 ELSE 0 END as check", "blabla") )
```

## Bugfixes

- Migrate to crystal v0.29
- Fix issue with combinaison of `join`, `distinct` and `select`

# v0.7

## Features

- Add `Clear::Interval` type

This type is related to the type `Clear::Interval` of PostgreSQL. It stores `month`, `days` and `microseconds` and can be used
with `Time` (Postgres' `datetime`) by adding or substracting it.

### Examples:

Usage in Expression engine:

```crystal
interval = Clear::Interval.new(months: 1, days: 1)

MyModel.query.where{ created_at - interval > updated_at  }.each do |model|
  # ...
end
```

It might be used as column definition, and added / removed to crystal `Time` object

```crystal
class MyModel
  include Clear::Model

  column i : Clear::Interval
end

puts "Expected time: #{Time.local + MyModel.first!.i}"
```

- Add `Clear::TimeInDay` columns type, which stands for the `time` object in PostgreSQL.

### Examples:

Usage as stand alone:
```crystal

time = Clear::TimeInDay.parse("12:33")
puts time.hour # 12
puts time.minutes # 0

Time.local.at(time) # Today at 12:33:00
time.to_s # 12:33:00
time.to_s(false) # don't show seconds => 12:33

time = time + 2.minutes #12:35
```

As with Interval, you might wanna use it as a column (use underlying `time` type in PostgreSQL):

```crystal
class MyModel
  include Clear::Model

  column i : Clear::TimeInDay
end
```


## Bug fixes
- Fix #115 (Thanks @pynixwang)
- Fix #118 (Thanks @russ)
- Fix #108


# v0.6

v0.6 should have shipped polymorphic relations, spec rework and improvement in
documentation. That's a lot of work (honestly the biggest improvement since v0)
and since already a lot of stuff have been integrated, I think it's better to
ship now and prepare it for the next release.

Since few weeks I'm using Clear in a full-time project, so I can see and correct
many bugs. Clear should now be more stable in term of compilation and should not
crash the compiler (which happened in some borderline cases).

## Features

- [EXPERIMENTAL] Add `<<` operation on collection which comes from `has_many` and `has_many through:`
- [EXPERIMENTAL] Add `unlink` method on collection which comes from `has_many through:`
- [EXPERIMENTAL] Add possibility to create model from JSON:

  ```crystal
    json = JSON.parse(%({"first_name": "John", "last_name": "Doe", "tags": ["customer", "medical"] }))
    User.new(json)
  ```

- Add of `pluck` and `pluck_col` methods to retrieve one or multiple column in a Tuple,
  which are super super fast and convenient!
- Add `Clear.with_cli` method to allow to use the CLI in your project. Check the documentation !
- Release of a guide and documentation to use Clear:  https://clear.gitbook.io/project/
- Additional comments in the source code
- `SelectQuery` now inherits from `Enumerable(Hash(String, Clear::SQL::Any))`
- Add optional block on `Enum` definition. This allow you to define custom methods for the enum:
  ```crystal
  Clear.enum ClientType, "company", "non_profit", "personnal" do
    def pay_vat?
      self == Personnal
    end
  end
  ```
- Add `?` support in `raw` method:
  ```crystal
    a = 1
    b = 1000
    c = 2
    where{ raw("generate_series(?, ?, ?)", a, b, c) }
  ```

## Breaking changes
- Migration: use of `table.column` instead of `table.${type}` (remove the method missing method); this was causing headache
  in some case where the syntax wasn't exactly followed, as the error output from the compiler was unclear.
- Renaming of `with_serial_pkey` to `primary_key`; refactoring of the macro-code allowing to add other type of keys.
  - Now allow `text`, `int` and `bigint` primary key, with the 0.5 `uid`, `serial` and `bigserial` primary keys.
- Renaming of `Clear::Model::InvalidModelError` to `Clear::Model::InvalidError` and `Clear::Model::ReadOnlyError` to
  `Clear::Model::ReadOnly` to simplify as those classes are already in the `Clear::Model` namespace
- `Model#set` methods has been transfered to `Model#reset`, and `Model#set` now change the status of the column to
  dirty. (see #81)

## Bug fixes
- Fix #66, #62

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
- `with_serial_pkey` use Int32 (type `:serial`) and Int64 (type `:longserial`) primary key instead of `UInt32` and `UInt64`. This would prevent issue with default `belongs_to` behavior and simplify static number assignation.

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
    last_week_users = User.query.where{ created_at.in?(7.day.ago..Time.local) }.count
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

- Patching segfault caused by weird architecture choice of mine over the `__pkey__` method.
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
