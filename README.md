# Clear

[![Build Status](https://travis-ci.org/anykeyh/clear.svg?branch=master)](https://travis-ci.org/anykeyh/clear) [![Docs](https://img.shields.io/badge/docs-available-brightgreen.svg)](https://anykeyh.github.io/clear/) [![GitHub release](https://img.shields.io/github/release/anykeyh/clear.svg)](https://github.com/anykeyh/clear/releases)

Clear is an ORM built for PostgreSQL and Crystal.
I do not want to make it compatible with others DBMS, so I can offers
better experience and connect to the advanced features of PostgreSQL.

## Features

Here some (but not all!) features offered yet by Clear !

* Expressive where query building (like Sequel!)

```crystal
Post.query.where{ ( title =~ /(^| )Awesome($| )/i ) & ( created_at.between(1.month.ago, Time.now) ) }
```

* N+1 query caching !

```crystal
Users.query.with_posts(&.published).each do #...
```

* CTE, locks, cursors and other advanced PG features are packed in !

```crystal
  LotsOfRecordModel.query.each_cursor(batch: 1_000) do |r| #...
```

* Migration system with integrated PostgreSQL subtilities (e.g. Foreign Key)

```crystal
  t.references to: "users", on_delete: "cascade", null: false
```

* Automatic presence validator through the columns declaration: Using `Type?`
  notation tell Clear that your column doesn't need to be present

```crystal
class MyModel
  include Clear::Model
  column x : String
end

m = MyModel.new
unless m.save
  puts m.print_errors # x should be present
end
```

* Mixins architecture, no class inheritance ! Include and play !

* Customizable columns converter PG <=> Crystal

```crystal
  record MyRecord, a : String, b: String

  class Clear::Model::Converter::CitextConverter
    def self.to_column(x : ::Clear::SQL::Any) : MyRecord?
      case x
      when Nil
        nil
      when Slice(UInt8)
        r = MyRecord.new
        # Convert here !
      else
        raise "bad format"
      end
    end

    def self.to_db(x : MyRecord?)
      # Convert here !
    end
  end
```

Please check the roadmap for more informations.

## Getting started

A full sample is available on the [wiki](https://github.com/anykeyh/clear/wiki/getting_started)

### Installation

In `shards.yml`

```yml
dependencies:
  clear:
    github: anykeyh/clear
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

  column hashed_password : String?

  def password=(x)
    self.encrypted_password = Encryptor.hash(x)
  end
end

```

#### Column types

`Number`, `String`, `Time`, `Boolean` and `Jsonb` structures are already mapped.
For other type of data, just create your own converter !

```crystal
class User
  include Clear::Model
  column my_custom_type : Custom::Type
end

# Just create a module following this naming convention:
module Clear::Model::Converter::Custom::TypeConverter
  def self.to_column(x : ::Clear::SQL::Any) : Custom::Type?
    # Deserialize your column here
  end

  def self.to_db(x : Custom::Type?)
    # Serialize your column here
  end
end
```

##### Column presence

Most of the ORM for Crystal are mapping column type as `Type | Nil` union.
It makes sens so we allow selection of some columns only of a model.
However, this have a caveats: columns are still accessible, and will return nil,
even if the real value of the column is not null !

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
u.email = "me@fiery.tech"
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

I've reimplemented `inspect` on model, to offer good debugging insights:

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

In this case, the `*` means a column is changed and the object is dirty and must
be saved on the database.

#### SQL Logging

One thing very important for a good ORM is to offer vision of the SQL
called under the hood.
Clear is offering SQL logging tools, with SQL syntax colorizing in your terminal.

For activation, simply setup the logger to `DEBUG` level !


```
Clear.logger.level = ::Logger::DEBUG
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

Presence validator is done using the type of the column:

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

It's for example the case of the `id` column, which take value after saving !

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

Validation fail if `model#errors` is not empty:

```crystal
  class MyModel
    #...
    def validate
      if column != "ABCD"
        add_error("column", "must be ABCD!")
      end
    end
  end
```

##### Unique validator

Please use `unique` feature of postgres. Unique validator at crystal level is a
non-go and lead to terrible race concurrency issues if your deploy on multiple nodes/pods.
It's an anti-pattern and must be avoided at any cost.

##### The validation and the presence system

In the case you try validation on a column which has not been initialized,
Clear will complain, telling you you cannot access to the column.
Let's see an example here:

```crystal
def validate
  add_error("first_name", "should not be empty") if first_name == ""
end
```

This validator will raise an exception, because first_name has never been initialized.
To avoid this, we have many way:
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

I recommend the 4th method in most of the cases you will faces.
Simple to write and easy to read !

### Migration

Clear offers of course a migration system.

Migration should have an `order` column set.
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

Migration must implement the method `change(dir : Migration::Direction)`

Direction is the current direction of the migration (up or down).
It provides few methods: `up?`, `down?`, `up(&block)`, `down(&block)`

You can create a table:

```crystal
  def change(dir)
    create_table(:test) do |t|
      t.string :first_name, index: true
      t.string :last_name, unique: true

      t.index "lower(first_name || ' ' || last_name)", using: :btree

      t.timestamps
    end
  end
```

#### Constraints

I strongly encourage to use the foreign key constraints of postgres for your references:

```crystal
  t.references to: "users", on_delete: "cascade", null: false
```

There's no plan to offer on Crystal level the `on_delete` feature, like
`dependent` in ActiveRecord. That's a standard PG feature, just set it
up in migration

## Architecture

In short, here is the architecture

```text
+---------------------------------------------+
|              Clear                          +
+---------------------------------------------+
|  Model | DB Views | Migrations | clear-cli  | < High Level Tools
+---------------+-----------------------------+
|  column | Validation | Converters            | < Mapping system
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

- [X] Hook callback
- [X] column mapping
- [X] Basic SQL: Select/Insert/Update/Delete
- [X] Cursored fetching
- [X] Debug Queries & Pretty Print
- [X] Scope
- [X] Locks
- [X] Relations
- [X] Having clause
- [X] CTE
- [X] Caching for N+1 Queries
- [X] Migrations
- [X] Validation
- [X] All logic of transaction, update, saving...
- [ ] DB Views => In progress
- [ ] Writing documentation
- [ ] clear-cli tool => In progress
- [ ] CitusDB Support ? => In mind
- [ ] Filling this checklist and drink a beer

I'm currently focusing on the DB views (nothing hard) and a CLI to
scaffold project with Kemal and Clear, manage migrations, and others tools !

## Licensing

This shard is provided under the MIT license.

## Contribute

All contributions are welcome ! As a specialized ORM for postgreSQL,
be sure a great contribution on a very specific PG feature will be incorporated
to this shard. I hope one day we will cover all the features of PG here !