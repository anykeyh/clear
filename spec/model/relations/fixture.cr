
class RelationMigration8001
  include Clear::Migration

  def change(dir)
    create_table "relation_spec_users" do |t|
      t.column "first_name", "string", null: false
    end

    create_table "relation_spec_user_infos" do |t|
      t.references to: "relation_spec_users", name: "user_id", on_delete: "cascade", null: true
      t.column "infos", "string", null: true
    end

    create_table "relation_spec_posts" do |t|
      t.references to: "relation_spec_users", name: "user_id", on_delete: "cascade", null: true
      t.column "content", "string", null: false
    end

    create_table "relation_spec_categories" do |t|
      t.column "name", "string", null: false
    end

    create_table "relation_spec_post_categories" do |t|
      t.references to: "relation_spec_posts",      name: "post_id", on_delete: "cascade", null: true
      t.references to: "relation_spec_categories", name: "category_id", on_delete: "cascade", null: true
    end
  end
end

module RelationSpec
  class UserInfo
    include Clear::Model

    primary_key

    column infos : String
    belongs_to user : User?, foreign_key: "user_id"
  end

  class User
    include Clear::Model

    primary_key

    has_one user_info : UserInfo, foreign_key: "user_id"
    # Same...
    has_many user_infos : UserInfo, foreign_key: "user_id"

    has_many posts : Post, foreign_key: "user_id"

    has_many categories : Category, through: :posts, relation: "categories"

    column first_name : String
  end

  class Post
    include Clear::Model

    primary_key

    belongs_to user : User, foreign_key: :user_id
    has_many user_infos : UserInfo, through: :user

    column content : String

    has_many categories : Category, through: :post_categories, relation: :category
    has_many post_categories : PostCategory, foreign_key: :post_id
  end

  class PostCategory
    include Clear::Model

    primary_key

    belongs_to category : Category
    belongs_to post : Post
  end

  class Category
    include Clear::Model

    primary_key

    column name : String

    has_many post_categories : PostCategory, foreign_key: :category_id
    has_many posts : Post, through: :post_categories
  end
end
