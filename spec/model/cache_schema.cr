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

class MigrateDb1
  include Clear::Migration

  def change(dir)
    dir.up do
      create_table "users" do |t|
        t.string "name", unique: true
      end

      create_table "categories" do |t|
        t.string "name", unique: true
      end

      create_table "user_infos", id: false do |t|
        t.references to: "users", on_delete: "cascade", primary: true
      end

      create_table "posts" do |t|
        t.references to: "users", on_delete: "cascade", null: false
        t.references to: "categories", on_delete: "set null"

        t.bool "published", default: false, null: false

        t.string "content", null: false
      end
    end
  end
end

MigrateDb1.new.apply(Clear::Migration::Direction::UP)
