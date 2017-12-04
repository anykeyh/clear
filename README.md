# Clear

[![Build Status](https://travis-ci.org/anykeyh/clear.svg?branch=master)](https://travis-ci.org/anykeyh/clear) [![Docs](https://img.shields.io/badge/docs-available-brightgreen.svg)](https://anykeyh.github.io/clear/) [![GitHub release](https://img.shields.io/github/release/anykeyh/clear.svg)](https://github.com/anykeyh/clear/releases)

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

Some basic and advanced features are already in, others are just in my head, and
others are just in the process "ok I'm gonna think about it later".
Please check the roadmap

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

In Clear, most of the objects are mixins and must be included to your classes:

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

Clear allows you to setup your own column types using converter:

```crystal
class User
  include Clear::Model
  column my_custom_type : Custom::Type
end

# Just create a module following this naming convention:
module Clear::Model::Converter::Custom::TypeConverter
  def self.to_column(x : ::Clear::SQL::Any) : Custom::Type?
    # Deserialize your field here
  end

  def self.to_db(x : Custom::Type?)
    # Serialize your field here
  end
end
```


##### Presence system explaination

Most of the ORM around are using column type as `Type | Nil` union.
In my opinion, it's bad. If your column type in postgres is `text NOT NULL`, it must
be mapped to `String`, and not to `String | Nil`, since you are sure no
column are `null`.

Moreover, it can lead to issues in this case:

```crystal
User.query.select("last_name").each do |usr|
  puts usr.first_name #Should it be nil since we don't select it??!
end
```

Clear offers another approach, storing each column in a wrapper.
Wrapper can be then of the type of the column as in postgres, or in `UNKNOWN` state.
This approach offers more flexibility:

```crystal
User.query.select("last_name").each do |usr|
  puts usr.first_name # << THIS WILL RAISE AN EXCEPTION, TELLING YOU first_name IS NOT INITIALIZED.
end
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

#### Simple query

Most of the queries are called via the method `query` on the model class.

##### Fetch a model

```crystal
# Get the first user
User.query.first #Get the first user, ordered by primary key

# Get a specific user
User.find!(1) #Get the first user, or throw exception if not found.

# Usage of query provide a `find_by` kind of method:
u : User? = User.query.find{ email =~ /yacine/i }
```

##### Fetch multiple models

You can use the query system to fetch multiple models.

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

```crystal
# count
user_on_gmail = User.query.where{ email.ilike "@gmail.com%" }.count #Note: count return is Int64
# min/max
max_id = User.query.where{ email.ilike "@gmail.com%" }.max("id", Int32)
# your own aggregate
weighted_avg = User.query.agg( "SUM(performance_weight * performance_score) / SUM(performance_weight)", Float64 )
```

##### Fetching associations

```crystal
User.query.each do |user|
  puts "User #{user.id} posts:"
  user.posts.each do |post| #Works, but will trigger a request for each user.
    puts "• #{post.id}"
  end
end
```

###### Caching association for N+1 request

Use the generated `with_xxx` method on the collection to get the association
cached and avoid N+1 request

```crystal
# Will call two requests only.
User.query.with_posts.each do |user|
  puts "User #{user.id} posts:"
  user.posts.each do |post|
    puts "• #{post.id}"
  end
end
```

###### Associations caching examples

Association cache can be tweaked, to encache subassociation, filters etc...

Example to cache `users => posts => category` (3 requests):

```crystal
# Will call two requests only.
User.query.with_posts(&.with_category).each do |user|
  puts "User #{user.id} posts:"
  user.posts.each do |post|
    puts "• #{post.id} @ #{post.category.name}"
  end
end
```

*DO / DO NOT:*

```crystal
# Will call two requests only.
User.query.with_posts.each do |user|
  puts "User #{user.id} published posts:"
  # NO: It won't cache the result, since the association is mutated via `where`
  user.posts.where({published: true}).each do |post|
    puts "• #{post.id}"
  end
end

#INSTEAD, DO:
User.query.with_posts(&.where({published: true})).each do |user|
  puts "User #{user.id} published posts:"
  # YES: the posts collection of user is already encached with the published filter :-)
  user.posts.each do |post|
    puts "• #{post.id}"
  end
end
```


##### Querying computed or foreign fields

In case you want fields computed by postgres, or stored in another table, you can use `fetch_column`.
By default, for performance reasons, `fetch_column` is set to false.

```crystal

users = User.query.select(email: "users.email",
  remark: "infos.remark").join("infos"){ infos.user_id == users.id }.to_a(fetch_columns: true)

# Now the column "remark" will be fetched into each user object

users.each do |u|
  puts "email: `#{u.email}`, remark: `#{u["remark"]?}`"
end


```

### Save & validation

#### Save

Object can be persisted, saved, updated:

```crystal
u = User.new
u.email = "test@example.com"
u.save! #Save or throw if unsavable (validation failed).
```

Columns can be checked:

```crystal
u = User.new
u.email = "test@example.com"
u.email_column.changed? # < Return "true"
```

#### Validation

##### Presence validator

Presence validator is done using the union type of the column:

```crystal
class User
  include Clear::Model

  column first_name : String # Must be present
  column last_name : String? # Can be null
end
```

###### `NOT NULL DEFAULT ...` CASE

In the case the data cannot be null but presence should not be check in clear, your can write:

```crystal
class User
    column id : Int64, primary: true, presence: false #id will be set using pg serial !
end
```

##### Unique validator

None. Use `unique` feature of postgres. Unique validator at crystal level is a
non-go and lead to terrible race concurrency issues.
It's an anti-pattern and must be avoided at any cost

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

##### Important note about validation and presence system

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

#5. Use the `ensure_than` helper (with block notation) !
def validate
  ensure_than(first_name, "should not be empty") do |field|
    field != ""
  end
end

```

I recommend the 4th method in most of the cases ;-)

### Migration

Clear offer a migration system. Migration class must be named with a number at the end, to order them:

```crystal
class Migration1
  include Clear::Migration

  def change(dir)
    #...
  end
end
```

#### Using filename

A good practice is to write down all your migrations one file per migration, and
naming them using the `[number]_migration_description.cr` pattern.
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

There's no plan to offer `dependent` system on the associations in Clear,
but instead to use the features of postgres.

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

- [X] Hook callback
- [X] Field mapping
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
- [ ] crclr tool => In progress
- [ ] CitusDB Support ? => In mind
- [ ] Filling this checklist and drink a beer

## Licensing

This shard is provided under the MIT license.