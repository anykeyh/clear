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

### Installation

In `shards.yml`
```yml

dependencies:
  clear:
    github: anykeyh/clear
```

Then require clear to your software:

```
require "clear"
```

### Model definition

In Clear, most of the objects are mixins and must be included to your classes:

#### Row definition

```
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

#### Custom types

Clear allow you to setup your custom types:

```
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

#### Associations

Clear offer `has_many`, `has_one`, `belongs_to` and `has_many through` associations:

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

#### Association cache

Associations provide caching system. See querying section of this manual.

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

##### Querying aggregate

```crystal
# count
user_on_gmail = User.query.where{ email.ilike "@gmail.com%" }.count #Note: count return is Int64
# min/max
max_id = User.query.where{ email.ilike "@gmail.com%" }.max("id", Int32)
# your own aggregate
weighted_avg = User.query.agg( "SUM(performance_weight * performance_score) / SUM(performance_weight)", Float64 )
```

##### Querying compound fields

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

```
u = User.new
u.email = "test@example.com"
u.save! #Save or throw if unsavable (validation failed).
```

Columns can be checked:

```
u = User.new
u.email = "test@example.com"
u.email_column.changed? # < Return "true"
```

#### Validation


### Migration


The best way to get started is to follow the [wiki](https://github.com/anykeyh/clear/wiki/getting_started)


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
- [ ] Validation
- [ ] All logic of transaction, update, saving...
- [ ] DB Views => In progress
- [ ] Writing documentation
- [ ] crclr tool => In progress
- [ ] CitusDB Support ? => In mind
- [ ] Filling this checklist and drink a beer

## Licensing

This shard is provided under the MIT license.