class Tag
  include Clear::Model

  column id : Int32, primary: true, presence: false

  column name : String

  has_many posts : Post, through: :model_post_tags, foreign_key: :post_id, own_key: :tag_id

  self.table = "model_tags"
end

class ChannelModel
  include Clear::Model

  self.table = "channels"

  column id : Int64, primary: true, presence: false
  column created_by_id : Int64

  column name : String
  column description : String
  column avatar_svg_uri : String

  timestamps
end

class Category
  include Clear::Model

  column id : Int32, primary: true, presence: false

  column name : String

  has_many posts : Post
  has_many users : User, through: :model_posts, foreign_key: :post_id, own_key: :category_id

  timestamps

  self.table = "model_categories"
end

class Post
  include Clear::Model

  column id : Int32, primary: true, presence: false

  column title : String

  column tags : Array(String), presence: false
  column flags : Array(Int64), presence: false, column_name: "flags_other_column_name"

  def validate
    ensure_than(title, "is not empty", &.size.>(0))
  end

  has_many tag_relations : Tag, through: :model_post_tags, foreign_key: :tag_id, own_key: :post_id

  belongs_to user : User, key_type: Int32?
  belongs_to category : Category, key_type: Int32?

  self.table = "model_posts"
end

class UserInfo
  include Clear::Model

  column id : Int32, primary: true, presence: false

  belongs_to user : User, key_type: Int32?
  column registration_number : Int64

  self.table = "model_user_infos"
end

class User
  include Clear::Model

  column id : Int32, primary: true, presence: false

  column first_name : String
  column last_name : String?
  column middle_name : String?
  column active : Bool?

  column notification_preferences : JSON::Any, presence: false

  has_many posts : Post, foreign_key: "user_id"
  has_one info : UserInfo?, foreign_key: "user_id"
  has_many categories : Category, through: :model_posts,
    own_key: :user_id, foreign_key: :category_id

  timestamps

  # Random virtual method
  def full_name=(x)
    self.first_name, self.last_name = x.split(" ")
  end

  def full_name
    {self.first_name, self.last_name}.join(" ")
  end

  self.table = "model_users"
end

class ExampleModelMigration1
  include Clear::Migration

  def change(dir)
    create_table "model_categories" do |t|
      t.column "name", "string"

      t.timestamps
    end

    create_table "model_tags", id: :serial do |t|
      t.column "name", "string", unique: true, null: false
    end

    create_table "model_users" do |t|
      t.column "first_name", "string"
      t.column "last_name", "string"

      t.column "active", "bool", null: true

      t.column "middle_name", type: "varchar(32)"

      t.column "notification_preferences", "jsonb", index: "gin", default: "'{}'"

      t.timestamps
    end

    create_table "model_posts" do |t|
      t.column "title", "string", index: true

      t.column "tags", "string", array: true, index: "gin", default: "ARRAY['post', 'arr 2']"
      t.column "flags_other_column_name", "bigint", array: true, index: "gin", default: "'{}'::bigint[]"

      t.references to: "model_users", name: "user_id", on_delete: "cascade"
      t.references to: "model_categories", name: "category_id", null: true, on_delete: "set null"
    end

    create_table "model_post_tags", id: false do |t|
      t.references to: "model_tags", name: "tag_id", on_delete: "cascade", null: false, primary: true
      t.references to: "model_posts", name: "post_id", on_delete: "cascade", null: false, primary: true

      t.index ["tag_id", "post_id"], using: :btree
    end

    create_table "model_user_infos" do |t|
      t.references to: "model_users", name: "user_id", on_delete: "cascade", null: true

      t.column "registration_number", "int64", index: true

      t.timestamps
    end
  end
end

def reinit_example_models
  reinit_migration_manager
  ExampleModelMigration1.new.apply
end
