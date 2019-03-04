class UserInfo
  include Clear::Model

  belongs_to user : User, primary: true
end

class User
  include Clear::Model

  column id : Int64, primary: true

  column name : String

  has_many posts : Post
end

class Category
  include Clear::Model

  column id : Int64, primary: true

  column name : String

  has_many posts : Post

  has_many users : User, through: Post
end

class Post
  include Clear::Model

  column id : Int64, primary: true

  column content : String

  column published : Bool = false

  scope "published" do
    where({published: true})
  end

  belongs_to user : User
  belongs_to category : Category
end

class MigrateSpec10
  include Clear::Migration

  def change(dir)
    dir.up do
      create_table "users" do |t|
        t.column "name", "string", unique: true
      end

      create_table "categories" do |t|
        t.column "name", "string", unique: true
      end

      create_table "user_infos", id: false do |t|
        t.references to: "users", on_delete: "cascade", primary: true
      end

      create_table "posts" do |t|
        t.references to: "users", on_delete: "cascade", null: false
        t.references to: "categories", on_delete: "set null"

        t.column "published", "bool", default: false, null: false

        t.column "content", "string", null: false
      end
    end
  end
end

# Monkey patch of QueryCache
# For adding statistics
# during spec
class Clear::Model::QueryCache
  class_getter cache_hitted : Int32 = 0

  def hit(relation_name, relation_value, klass : T.class) : Array(T) forall T
    @@cache_hitted += 1
    previous_def
  end

  def self.reset_counter
    @@cache_hitted = 0
  end
end
