<p align="center"><img src="design/logo1.png" alt="clear" height="200px"></p>

# Clear
[![Build Status](https://travis-ci.org/anykeyh/clear.svg?branch=master)](https://travis-ci.org/anykeyh/clear) [![Docs](https://img.shields.io/badge/docs-available-brightgreen.svg)](https://anykeyh.github.io/clear/) [![GitHub release](https://img.shields.io/github/release/anykeyh/clear.svg)](https://github.com/anykeyh/clear/releases)
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-20-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

Clear is an ORM built specifically for PostgreSQL in Crystal.

It's probably the most advanced ORM for PG on Crystal in term of features offered.
It features Active Record pattern models, and a low-level SQL builder.

You can deal out of the box with jsonb, tsvectors, cursors, CTE, bcrypt password,
array, uuid primary key, foreign constraints... and other things !
It also has a powerful DSL to construct `where` and `having` clauses.

The philosophy beneath is to please me (and you !) with emphasis made on business
code readability and minimal setup.

The project is quite active and well maintened, too !

## Resources

- [Online Manual and Getting Started](https://clear.gitbook.io/project/)
- [Auto-generated API Documentation](https://anykeyh.github.io/clear/)
- [Changelog](https://github.com/anykeyh/clear/blob/master/CHANGELOG.md)

## Why to use Clear ?

In few seconds, you want to use Clear if:

- [X] You want an expressive ORM. Put straight your thought to your code !
- [X] You'd like to use advanced Postgres features without hassle
- [X] You are aware of the pros and cons of the Active Records pattern

You don't want to use Clear if:

- [ ] You're not willing to use PostgreSQL
- [ ] You're looking for a minimalist ORM / Data Mapper
- [ ] You need something which doesn't evolve, with breaking changes.
      Clear is still in alpha but starting to mature !


## Features

- Active Record pattern based ORM
- Expressiveness as mantra - even with advanced features like jsonb, regexp... -
```crystal
  # Like ...
  Product.query.where{ ( type == "Book" ) & ( metadata.jsonb("author.full_name") == "Philip K. Dick" ) }
  # ^--- will use @> operator, to relay on your gin index. For real.

  Product.query.where{ ( products.type == "Book" ) & ( products.metadata.jsonb("author.full_name") != "Philip K. Dick" ) }
  # ^--- this time will use -> notation, because no optimizations possible :/

  # Or...
  User.query.where{ created_at.in? 5.days.ago .. 1.day.ago }

  # Or even...
  ORM.query.where{ ( description =~ /(^| )awesome($| )/i ) }.first!.name # Clear! :-)
```
- Proper debug information
  - Log and colorize query. Show you the last query if your code crash !
  - If failing on compile for a good reason, give proper explaination (or at least try)
- Migration system
- Validation system
- N+1 query avoidance strategy
- Transaction, rollback & savepoint
- Access to CTE, locks, cursors, scope, pagination, join, window, multi-connection and many others features
- Model lifecycle/hooks
- JSONB, UUID, FullTextSearch

### Installation

In `shards.yml`

```yml
dependencies:
  clear:
    github: anykeyh/clear
    branch: master
```

Then:

```crystal
  require "clear"
```

### Model definition

Clear offers some mixins, just include them in your classes to *clear* them:

#### Column mapping

```crystal

class User
  include Clear::Model

  column id : Int64, primary: true

  column email : String

  column first_name : String?
  column last_name : String?

  column encrypted_password : Crypto::Bcrypt::Password

  def password=(x)
    self.encrypted_password = Crypto::Bcrypt::Password.create(password)
  end
end

```

#### Column types

- `Number`, `String`, `Time`, `Boolean` and `Jsonb` structures are already mapped.
- `Numeric` ([arbitrary precision number](https://www.postgresql.org/docs/9.6/datatype-numeric.html)) is also supported
- `Array` of primitives too.
For other type of data, just create your own converter !

```crystal
class Clear::Model::Converter::MyClassConversion
  def self.to_column(x) : MyClass?
    case x
    when String
      MyClass.from_string(x)
    when Slice(UInt8)
      MyClass.from_slice(x)
    else
      raise "Cannot convert from #{x.class} to MyClass"
    end
  end

  def self.to_db(x : UUID?)
    x.to_s
  end
end

Clear::Model::Converter.add_converter("MyClass", Clear::Model::Converter::MyClassConversion)
```

##### Column presence

Most of the ORM for Crystal are mapping column type as `Type | Nil` union.
It makes sense so we allow selection of some columns only of a model.
However, this have a caveats: columns are still accessible, and will return nil,
even if the real value of the column is not null!

Moreover, most of the developers will enforce nullity only on their programming
language level via validation, but not on the database, leading to inconsistency.

Therefore, we choose to throw exception whenever a column is accessed before
it has been initialized and to enforce presence through the union system of
Crystal.

Clear offers this through the use of column wrapper.
Wrapper can be of the type of the column as in postgres, or in `UNKNOWN` state.
This approach offers more flexibility:

```crystal
User.query.select("last_name").each do |usr|
  puts usr.first_name #Will raise an exception, as first_name hasn't been fetched.
end

u = User.new
u.first_name_column.defined? #Return false
u.first_name_column.value("") # Call the value or empty string if not defined :-)
u.first_name = "bonjour"
u.first_name_column.defined? #Return true now !
```

Wrapper give also some pretty useful features:

```crystal
u = User.new
u.email = "me@myaddress.com"
u.email_column.changed? # TRUE
u.email_column.revert
u.email_column.defined? # No more
```

#### Associations

Clear offers `has_many`, `has_one`, `belongs_to` and `has_many through` associations:

```crystal
class Security::Action
  belongs_to role : Role
end

class Security::Role
  has_many user : User
end

class User
  include Clear::Model

  has_one user_info : UserInfo
  has_many posts : Post

  belongs_to role : Security::Role

  # Use of the standard keys (users_id <=> security_role_id)
  has_many actions : Security::Action, through: Security::Role
end
```

### Querying

Clear offers a collection system for your models. The collection system
takes origin to the lower API `Clear::SQL`, used to build requests.

#### Simple query

##### Fetch a model

To fetch one model:

```crystal
# 1. Get the first user
User.query.first #Get the first user, ordered by primary key

# Get a specific user
User.find!(1) #Get the first user, or throw exception if not found.

# Usage of query provides a `find_by` kind of method:
u : User? = User.query.find{ email =~ /yacine/i }
```

##### Fetch multiple models

To prepare a collection, juste use `Model#query`.
Collections include `SQL::Select` object, so all the low level API
(`where`, `join`, `group_by`, `lock`...) can be used in this context.

```crystal
# Get multiple users
User.query.where{ (id >= 100) & (id <= 200) }.each do |user|
  # Do something with user !
end

#In case you know there's millions of row, use a cursor to avoid memory issues !
User.query.where{ (id >= 1) & (id <= 20_000_000) }.each_cursor(batch: 100) do |user|
  # Do something with user; only 100 users will be stored in memory
  # This method is using pg cursor, so it's 100% transaction-safe
end
```

##### Aggregate functions

Call aggregate functions from the query is possible. For complex aggregation,
I would recommend to use the `SQL::View` API (note: Not yet developed),
and keep the model query for _fetching_ models only

```crystal
# count
user_on_gmail = User.query.where{ email.ilike "@gmail.com%" }.count #Note: count return is Int64
# min/max
max_id = User.query.where{ email.ilike "@gmail.com%" }.max("id", Int32)
# your own aggregate
weighted_avg = User.query.agg( "SUM(performance_weight * performance_score) / SUM(performance_weight)", Float64 )
```

##### Fetching associations

Associations are basically getter which create predefined SQL.
To access to an association, just call it !

```crystal
User.query.each do |user|
  puts "User #{user.id} posts:"
  user.posts.each do |post| #Works, but will trigger a request for each user.
    puts "• #{post.id}"
  end
end
```

###### Caching association for N+1 request

For every association, you can tell Clear to encache the results to avoid
N+1 queries, using `with_XXX` on the collection:

```crystal
# Will call two requests only.
User.query.with_posts.each do |user|
  puts "User #{user.id} posts:"
  user.posts.each do |post|
    puts "• #{post.id}"
  end
end
```

Note than Clear doesn't perform a join method, and the SQL produced will use
the operator `IN` on the association.

In the case above:

- The first request will be

```
  SELECT * FROM users;
```

- Thanks to the cache, a second request will be called before fetching the users:

```
  SELECT * FROM posts WHERE user_id IN ( SELECT id FROM users )
```

I have plan in a late future to offer different query strategies for the cache (e.g. joins, unions...)

###### Associations caching examples

When you use the caching system of the association, using filters on association will
invalidate the cache, and N+1 query will happens.

For example:

```crystal
User.query.with_posts.each do |user|
  puts "User #{user.id} published posts:"
  # Here: The cache system will not work. The cache on association
  # is invalidated by the filter `where`.
  user.posts.where({published: true}).each do |post|
    puts "• #{post.id}"
  end
end
```

The way to fix it is to filter on the association itself:

```crystal
User.query.with_posts(&.where({published: true})).each do |user|
  puts "User #{user.id} published posts:"
  # The posts collection of user is already encached with the published filter
  user.posts.each do |post|
    puts "• #{post.id}"
  end
end
```

Note than, of course in this example `user.posts` are not ALL the posts but only the
`published` posts

Thanks to this system, we can stack it to encache long distance relations:

```crystal
# Will cache users<=>posts & posts<=>category
# Total: 3 requests !
User.query.with_posts(&.with_category).each do |user|
  #...
end
```

##### Querying computed or foreign columns

In case you want columns computed by postgres, or stored in another table, you can use `fetch_column`.
By default, for performance reasons, `fetch_columns` option is set to false.

```crystal
users = User.query.select(email: "users.email",
  remark: "infos.remark").join("infos"){ infos.user_id == users.id }.to_a(fetch_columns: true)

# Now the column "remark" will be fetched into each user object.
# Access can be made using `[]` operator on the model.

users.each do |u|
  puts "email: `#{u.email}`, remark: `#{u["remark"]?}`"
end
```

### Inspection & SQL logging

#### Inspection

`inspect` over model offers debugging insights:

```text
  p # => #<Post:0x10c5f6720
          @attributes={},
          @cache=
           #<Clear::Model::QueryCache:0x10c6e8100
            @cache={},
            @cache_activation=Set{}>,
          @content_column=
           "...",
          @errors=[],
          @id_column=38,
          @persisted=true,
          @published_column=true,
          @read_only=false,
          @title_column="Lorem ipsum torquent inceptos"*,
          @user_id_column=5>
```

In this case, the `*` means a column is changed and the object is dirty and diverge from the database.

#### SQL Logging

One thing very important for a good ORM is to offer vision of the SQL
called under the hood.
Clear is offering SQL logging tools, with SQL syntax colorizing in your terminal.

For activation, simply setup the log to `:debug` level


```
::Log.builder.bind "clear.*", Log::Severity::Debug, Log::IOBackend.new
```

### Save & validation

#### Save

Object can be persisted, saved, updated:

```crystal
u = User.new
u.email = "test@example.com"
u.save! #Save or throw if unsavable (validation failed).
```

Columns can be checked & reverted:

```crystal
u = User.new
u.email = "test@example.com"
u.email_column.changed? # < Return "true"
u.email_column.revert # Return to #undef.
```

#### Validation

##### Presence validator

Presence validation is done using the type of the column:

```crystal
class User
  include Clear::Model

  column first_name : String # Must be present
  column last_name : String? # Can be null
end
```

###### `NOT NULL DEFAULT ...` CASE


There's a case when a column CAN be null inside Crystal, if not persisted,
but CANNOT be null inside Postgres.

For example in the case of the `id` column, the value is generated during insert !

In this case, you can write:

```crystal
class User
    column id : Int64, primary: true, presence: false #id will be set using pg serial !
end
```

Thus, in all case this will fail:

```
u = User.new
u.id # raise error
```

##### Other validators

When you save your model, Clear will call first the presence validators, then
call your custom made validators. All you have to do is to reimplement
the `validate` method:

```crystal
class MyModel
#...
  def validate
    # Your code goes here
  end
end
```

Validation fails if `model#errors` is not empty:

```crystal
  class MyModel
    #...
    def validate
      if first_name_column.defined? && first_name != "ABCD" #< See below why `defined?` must be called.
        add_error("first_name", "must be ABCD!")
      end
    end
  end
```

##### Unique validator

Please use the `unique` constraint feature of postgres. Unique validation outside of the database
does not protect against race conditions between multiple fibers/threads/nodes/pods.
It's an anti-pattern and must be avoided at any cost.

##### The validation and the presence system

If you try to validate a column which has not been initialized,
Clear will complain, telling you you cannot access to the column.
Let's see an example here:

```crystal
class MyModel
  #...
  def validate
    add_error("first_name", "should not be empty") if first_name == ""
  end
end

MyModel.new.save! #< Raise unexpected exception, not validation failure :(
```

This validator will raise an exception, because first_name has never been initialized.
To avoid this, we have many options:
```crystal
# 1. Check presence:

def validate
  if first_name_column.defined? #Ensure we have a value here.
    add_error("first_name", "should not be empty") if first_name == ""
  end
end

# 2. Use column object + default value
def validate
  add_error("first_name", "should not be empty") if first_name_column.value("") == ""
end

# 3. Use the helper macro `on_presence`
def validate
  on_presence(first_name) do
    add_error("first_name", "should not be empty") if first_name == ""
  end
end

#4. Use the helper macro `ensure_than`
def validate
  ensure_than(first_name, "should not be empty", &.!=(""))
end

#5. Use the `ensure_than` helper (but with block notation) !
def validate
  ensure_than(first_name, "should not be empty") do |column|
    column != ""
  end
end

```

I recommend the 4th method in most scenarios.
Simple to write and easy to read !

### Migration

Clear offers of course a migration system.

Migration should have an number at the end of the class name
to define the order migrations should be ran in.
This number can be wrote at the end of the class itself:

```crystal
class Migration1
  include Clear::Migration

  def change(dir)
    #...
  end
end
```

#### Using filename

Another way is to write down all your migrations one file per migration, and
naming the file using the `[number]_migration_description.cr` pattern.
In this case, the migration class name doesn't need to have a number at the end of the class name.

```crystal
# in src/db/migrations/1234_create_table.cr
class CreateTable
  include Clear::Migration

  def change(dir)
    #...
  end
end
```

#### Migration examples

Migrations must implement the method `change(dir : Migration::Direction)`

Direction is the current direction of the migration (up or down).
It provides few methods: `up?`, `down?`, `up(&block)`, `down(&block)`

You can create a table:

```crystal
  def change(dir)
    create_table(:test) do |t|
      t.column :first_name, :string, index: true
      t.column :last_name, :string, unique: true

      t.index "lower(first_name || ' ' || last_name)", using: :btree

      t.timestamps
    end
  end
```

#### Constraints

I strongly encourage use of postgres's foreign key constraints for your references:

```crystal
  t.references to: "users", on_delete: "cascade", null: false
```

There's no plan to offer on Crystal level the `on_delete` feature, like
`dependent` in ActiveRecord. That's a standard PG feature, just set it
up in your migrations.

## Performances

Models add a layer of computation. Below is a sample with a very simple model
(two integer columns), with fetching of 100k rows over 1M rows database, using --release flag:


| Method                     |        | Total time            | Speed        |
| --------------------------:|-------:|-----------------------|-------------:|
|          Simple load 100k  |  12.04 |  ( 83.03ms) (± 3.87%) | 2.28× slower |
|               With cursor  |   8.26 |  ( 121.0ms) (± 1.25%) | 3.32× slower |
|           With attributes  |  10.30 |  ( 97.12ms) (± 4.07%) | 2.67× slower |
| With attributes and cursor |   7.55 |  (132.52ms) (± 2.39%) | 3.64× slower |
|                  SQL only  |  27.46 |  ( 36.42ms) (± 5.05%) |      fastest |


- `Simple load 100k` is using an array to fetch the 100k rows.
- `With cursor` is querying 1000 rows at a time
- `With attribute` setup a hash to deal with unknown attributes in the model (e.g. aggregates)
- `With attribute and cursor` is doing cursored fetch with hash attributes created
- `SQL only` build and execute SQL using SQL::Builder

As you can see, it takes around 100ms to fetch 100k rows for this simple model (SQL included).
If for more complex model, it would take a bit more of time, I think the performances
are quite reasonable, and tenfold or plus faster than Rails's ActiveRecord.

## Licensing

This shard is provided under the MIT license.

## Contribution

All contributions are welcome! As a specialized ORM for PostgreSQL,
be sure a great contribution on a very specific PG feature will be incorporated
to this shard.
I hope one day we will cover all the features of PG here !

### Running Tests

In order to run the test suite, you will need to have the PostgresSQL service locally available via a socket for access with psql. psql will attempt to use the 'postgres' user to create the test database. If you are working with a newly installed database that may not have the postgres user, this can be created with `createuser -s postgres`.

## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):
<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="http://blog.bashme.org"><img src="https://avatars3.githubusercontent.com/u/684?v=4" width="100px;" alt=""/><br /><sub><b>Russ Smith</b></sub></a><br /><a href="https://github.com/anykeyh/clear/commits?author=russ" title="Code">💻</a></td>
    <td align="center"><a href="http://www.amberframework.org "><img src="https://avatars2.githubusercontent.com/u/1685772?v=4" width="100px;" alt=""/><br /><sub><b>Elias Perez</b></sub></a><br /><a href="https://github.com/anykeyh/clear/commits?author=eliasjpr" title="Documentation">📖</a></td>
    <td align="center"><a href="https://namechk.com"><img src="https://avatars1.githubusercontent.com/u/2391?v=4" width="100px;" alt=""/><br /><sub><b>Jeremy Woertink</b></sub></a><br /><a href="https://github.com/anykeyh/clear/commits?author=jwoertink" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/mamantoha"><img src="https://avatars2.githubusercontent.com/u/61285?v=4" width="100px;" alt=""/><br /><sub><b>Anton Maminov</b></sub></a><br /><a href="https://github.com/anykeyh/clear/commits?author=mamantoha" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/remydev"><img src="https://avatars1.githubusercontent.com/u/10176486?v=4" width="100px;" alt=""/><br /><sub><b>remydev</b></sub></a><br /><a href="https://github.com/anykeyh/clear/commits?author=remydev" title="Documentation">📖</a></td>
    <td align="center"><a href="http://jack.codes"><img src="https://avatars2.githubusercontent.com/u/3958636?v=4" width="100px;" alt=""/><br /><sub><b>Jack Turnbull</b></sub></a><br /><a href="https://github.com/anykeyh/clear/issues?q=author%3Ajackturnbull" title="Bug reports">🐛</a></td>
    <td align="center"><a href="https://github.com/Blacksmoke16"><img src="https://avatars1.githubusercontent.com/u/12136995?v=4" width="100px;" alt=""/><br /><sub><b>Blacksmoke16</b></sub></a><br /><a href="https://github.com/anykeyh/clear/commits?author=Blacksmoke16" title="Code">💻</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://github.com/007lva"><img src="https://avatars3.githubusercontent.com/u/1860816?v=4" width="100px;" alt=""/><br /><sub><b>luigi</b></sub></a><br /><a href="https://github.com/anykeyh/clear/commits?author=007lva" title="Code">💻</a></td>
    <td align="center"><a href="http://zauner900.net"><img src="https://avatars0.githubusercontent.com/u/30139?v=4" width="100px;" alt=""/><br /><sub><b>Matthias Zauner</b></sub></a><br /><a href="https://github.com/anykeyh/clear/issues?q=author%3Azauner" title="Bug reports">🐛</a></td>
    <td align="center"><a href="https://westonganger.com"><img src="https://avatars3.githubusercontent.com/u/3414795?v=4" width="100px;" alt=""/><br /><sub><b>Weston Ganger</b></sub></a><br /><a href="https://github.com/anykeyh/clear/commits?author=westonganger" title="Documentation">📖</a></td>
    <td align="center"><a href="https://github.com/pynixwang"><img src="https://avatars0.githubusercontent.com/u/1189879?v=4" width="100px;" alt=""/><br /><sub><b>Pynix Wang</b></sub></a><br /><a href="https://github.com/anykeyh/clear/commits?author=pynixwang" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/Vici37"><img src="https://avatars2.githubusercontent.com/u/1459505?v=4" width="100px;" alt=""/><br /><sub><b>Vici37</b></sub></a><br /><a href="https://github.com/anykeyh/clear/commits?author=Vici37" title="Code">💻</a></td>
    <td align="center"><a href="http://karoly.io"><img src="https://avatars2.githubusercontent.com/u/1334622?v=4" width="100px;" alt=""/><br /><sub><b>Niklas Karoly</b></sub></a><br /><a href="https://github.com/anykeyh/clear/commits?author=nik736" title="Documentation">📖</a></td>
    <td align="center"><a href="https://github.com/Acciaiodigitale"><img src="https://avatars0.githubusercontent.com/u/26814295?v=4" width="100px;" alt=""/><br /><sub><b>Massimiliano Bertinetti</b></sub></a><br /><a href="https://github.com/anykeyh/clear/commits?author=Acciaiodigitale" title="Documentation">📖</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://github.com/batarian71"><img src="https://avatars1.githubusercontent.com/u/36008612?v=4" width="100px;" alt=""/><br /><sub><b>batarian71</b></sub></a><br /><a href="#design-batarian71" title="Design">🎨</a></td>
    <td align="center"><a href="https://github.com/anykeyh"><img src="https://avatars2.githubusercontent.com/u/2456898?v=4" width="100px;" alt=""/><br /><sub><b>Yacine Petitprez</b></sub></a><br /><a href="#maintenance-anykeyh" title="Maintenance">🚧</a></td>
    <td align="center"><a href="https://github.com/alex-min"><img src="https://avatars1.githubusercontent.com/u/1898825?v=4" width="100px;" alt=""/><br /><sub><b>Alexandre</b></sub></a><br /><a href="https://github.com/anykeyh/clear/commits?author=alex-min" title="Code">💻</a></td>
    <td align="center"><a href="https://duke-nguyen.netlify.app"><img src="https://avatars1.githubusercontent.com/u/58082199?v=4" width="100px;" alt=""/><br /><sub><b>Anh (Duke) Nguyen</b></sub></a><br /><a href="https://github.com/anykeyh/clear/commits?author=dukeraphaelng" title="Code">💻</a></td>
    <td align="center"><a href="https://yujiri.xyz"><img src="https://avatars1.githubusercontent.com/u/16864184?v=4" width="100px;" alt=""/><br /><sub><b>Ryan Westlund</b></sub></a><br /><a href="https://github.com/anykeyh/clear/commits?author=yujiri8" title="Documentation">📖</a></td>
    <td align="center"><a href="https://github.com/caspiano"><img src="https://avatars2.githubusercontent.com/u/18466497?v=4" width="100px;" alt=""/><br /><sub><b>Caspian Baska</b></sub></a><br /><a href="https://github.com/anykeyh/clear/commits?author=caspiano" title="Code">💻</a></td>
  </tr>
</table>

<!-- markdownlint-enable -->
<!-- prettier-ignore-end -->
<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
