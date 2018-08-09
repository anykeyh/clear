# master/HEAD

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
