# To create the database (comment/uncomment if you want)
`echo "DROP DATABASE IF EXISTS sample_for_wiki;" | psql -U postgres`
`echo "CREATE DATABASE sample_for_wiki;" | psql -U postgres`

# Unleash the kraken !!!
require "../../src/clear"

# Initialize the connection
Clear::SQL.init("postgres://postgres@localhost/sample_for_wiki")

# Setting log level to DEBUG will allow you to see the requests made by the system
Log.builder.bind "clear.*", Log::Severity::Debug, Log::IOBackend.new

# Because it's a step by step tutorial
def pause
  puts("You can investigate your terminal... Just press any key to continue!")
  gets
end

# Create a migration
# A migration follow naming constraint to keep the migration order; this naming constraint can be file based, or class based
# [NUMBER]_name.cr => Use the filename as constraint for order of the migration
# class ClassName[NUMBER] => Use the number at the end of the class name as constraint for order of the migration
# You can also redefine `uid` in migration, if you don't want to have number in your filename or classname
# Here we are going to use the number into the class, to keep all the source of our application
# into the same file
class FirstMigration1
  include Clear::Migration

  # Everything is included in `change` method
  def change(dir)               # < dir is the direction of the migration, up or down
    dir.up { }                  # This block will be trigger only when we charge a migration into the database !
    create_table "users" do |t| # We create the table users
    # By default, a serial bigint named "id" will be created. You can remove this behavior adding `id: false` in create_table parameters
      t.column :first_name, :string, index: true, null: false
      t.column :last_name, :string, index: true, null: false
      t.column :password_encrypted, :string
      t.column :email, :string, unique: true # Add unique constraint
    end

    create_table "posts" do |t|
      # Create a foreign key constraint in PG to users
      t.references to: "users", on_delete: "cascade", null: false
      t.column :title, :string, index: true # Creation of an index on title. Soon we will be able to use tsvector !
      t.column :content, :string, null: true
      t.column :published, :bool, default: false, null: false
    end
  end
end

# we can write down our models now !

class User
  include Clear::Model
  self.table = "users"

  # Adding a primary key is mandatory in models
  # if you want to use relations !
  primary_key # By default, the primary key is `id`

  column first_name : String
  column last_name : String

  # Using the column is quite straight forward...
  def full_name
    [first_name, last_name].join(" ")
  end

  # Note here, because password_encrypted can be nullable in the database,
  # you expect it to be nullable in Clear too.
  column password_encrypted : String?

  column email : String

  # Possible relation are: has_one, has_many, has_many .. through and belongs_to
  has_many posts : Post
end

class Post
  include Clear::Model
  self.table = "posts"

  primary_key

  belongs_to user : User

  column title : String
  column content : String?

  column published : Bool

  # Scope are helpers on class level, which helps to filter the query and can
  # be chained !
  scope(published) { where({published: true}) }
end

# Now we have a migration, it's time to migrate it !
# Note if you launch your application again, the migration won't be applied again.
Clear::Migration::Manager.instance.apply_all
pause

# Now it's time to put some data, but first, let's delete everything from our database.
# There's multiple way to delete, but the simplest is to use the SQL builder
# (Also like this I can show it to you !)
# Clear offers a great query building interface.

# Ok, let's delete all the users!
# Note: We cannot yet do any "TRUNCATE" operation :(, but soon, I hope !
Clear::SQL.delete("users").execute
pause

# Since the posts have foreign constraints to users with cascaded delete (see migration)
# we assume the posts are deleted, too !

# Now it's time to create users and post !
# But first, let's create a lorem ipsum function !
def lorem(count)
  dictionnary = %w(si dolor es null nunc tempor eros urna vitae malesuada nibh
    elementum id class aptent taciti sociosqu ad litora torquent per conubia
    nostra per inceptos himenaeos pellentesque molestie vitae nisi vitae ornare
    sed condimentum sed arcu non rhoncus mauris fringilla sit amet ligula ut
    ultrices aenean maximus enim nec malesuada pellentesque suspendisse hendrerit
    dignissim sapien eu malesuada magna laoreet vel)
  raise "count must be > 2" unless count > 2 # Always fail fast !
  # This should do the trick!
  "Lorem ipsum" + dictionnary.sample(count - 2).join(" ")
end

# Now it's time to create our users !
# Let's create 200 users !
200.times do |idx|
  # This is the simplest way to create and save the user in one operation
  u = User.create!({first_name: "user#{idx}", last_name: "malcom#{idx}", email: "user#{idx}@localhost"})
  # We can then build posts for the users
  (1..12).to_a.sample.times do # Each user own 1 to 12 posts !
    p = u.posts.build
    # As you can see, the post already have the ID of the user, so no need to make the link manually !
    p.title = lorem(rand(4..8))
    p.content = lorem(rand(10..200))
    p.published = [true, false].sample # Half of our posts are not published; this is to check later with the scope!
    p.save!                            # We can then save the post !
  end
end

# Ok, let's see if I can count all the posts with `enim` (one of the lorem ipsum word!) into the title:
puts Post.query.where { title =~ /(^| )enim( |$)/i }.count
pause
# It wasnt so hard :-). You can notice here I use the Clear's expression engine, idea
# completely stolen to the famous Sequel ORM !
# We also use the power of postgres to use regex straight to the database ! Yeah !

# Ok, now we have a filled database, let's show up the posts of our first 10 users !
# To start a collection gathering, you need to use "query" (or you can use a scope also)
User.query.limit(5).each do |user|
  puts "Post of user: #{user.full_name}"
  user.posts.each do |p|
    puts p.title
  end
end
pause

# How wait... It's boring it calls, SQL query for each user !
# The solution is here ! Let's tell Clear we want the posts of the user!
User.query.with_posts.limit(5).each do |user|
  puts "Post of user: #{user.full_name}"
  user.posts.each do |p|
    puts p.title
  end
end
pause

# But wait... I want to show only published posts of the user, how can I do?
# Answer: Filter the posts !
User.query.with_posts(&.published).limit(5).each do |user|
  puts "Post of user: #{user.full_name}"
  user.posts.each do |p|
    puts p.title
  end
end
pause
