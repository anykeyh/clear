require "spec"
require "../spec_helper"

module ModelSpec
  class Post
    include Clear::Model

    column id : Int32, primary: true

    column title : String?

    belongs_to user : User

    self.table = "posts"
  end

  class UserInfo
    include Clear::Model

    column(id : Int32, primary: true)

    belongs_to user : User
    column registration_number : Int64

    self.table = "user_infos"
  end

  struct User
    include Clear::Model

    before(:save) { |u| }

    column(id : Int32, primary: true)

    column(first_name : String?)
    column(last_name : String?)
    column(middle_name : String?)

    column(notification_preferences : JSON::Any)

    has posts : Array(Post)
    has info : UserInfo

    timestamps

    self.table = "users"
  end

  class UserMigration1
    include Clear::Migration

    def change(dir)
      create_table "users" do |t|
        t.text "first_name"
        t.text "last_name"
        t.text "middle_name"

        t.jsonb "notification_preferences", index: "gin", default: Clear::Expression["{}"]

        t.timestamps
      end

      create_table "user_infos" do |t|
        t.references to: "users", name: "user_id", on_delete: "cascade"

        t.int64 "registration_number", index: true

        t.timestamps
      end

      create_table "posts" do |t|
        t.string "title", index: true
        t.references to: "users", on_delete: "cascade"
      end
    end
  end

  UserMigration1.new.apply(Clear::Migration::Direction::UP)

  describe "Clear::Model" do
    context "fields management" do
      it "can load from array" do
        u = User.new({id: 123})
        u.id.should eq 123
        u.persisted?.should be_false
      end

      it "can detect persistance" do
        u = User.new({id: 1}, persisted: true)
        u.persisted?.should be_true
      end

      it "can detect change in fields" do
        u = User.new({id: 1})
        u.id = 2
        u.update_h.should eq({"id" => 2})
        u.id = 1
        u.update_h.should eq({} of String => ::DB::Any) # no more change, because id is back to the same !
      end

      it "can save the model" do
        u = User.new({id: 1})
        u.id = 2 # Force the change!
        u.save
      end

      it "can save persisted model" do
        u = User.new
        u.persisted?.should eq false
        u.first_name = "hello"
        u.last_name = "world"
        u.save

        u.persisted?.should eq true
        u.id # Should not raise
      end

      it "can load models" do
        User.query.each do |u|
          u.id.should_not eq(nil)
        end
      end

      it "can read through cursor" do
        User.query.each_with_cursor(batch: 50) do |u|
          u.id.should_not eq(nil)
        end
      end

      it "define constraints on has-many to build object" do
        p = User.query.first!.posts.build
      end

      it "can encache N+1 query on belongs_to, has_one" do
        User.create [
          {id: 100, first_name: "Yacine"},
          {id: 101, first_name: "Olivier"},
          {id: 102, first_name: "Kevin"},
          {id: 103, first_name: "Matz"},
        ]

        Post.create [
          {id: 100, user_id: 100, title: "Cool Post 1"},
          {id: 101, user_id: 100, title: "Cool Post 2"},
          {id: 102, user_id: 100, title: "Cool Post 3"},
          {id: 103, user_id: 100, title: "Cool Post 4"},
        ]

        UserInfo.create [
          {id: 100, user_id: 100, registration_number: 123},
        ]

        Post.query.with_user.each do |u|
          u.user # Must trigger the cache
        end

        cache = Clear::Model::Cache.instance
        cache.hit.should eq 4
        cache.miss.should eq 0

        cache.clear

        Post.query.each do |u|
          u.user # Do not trigger cache
        end

        cache.hit.should eq 0
        cache.miss.should eq 4

        cache.clear
        User.query.where { id == 100 }.first!.info
        cache.hit.should eq 0
        cache.miss.should eq 1

        cache.clear
        cache.with_cache do
          User.query.with_info.where { id == 100 }.first!.info
          cache.hit.should eq 1
          cache.miss.should eq 0
        end
      end

      it "can read and write jsonb" do
        u = User.query.first!

        u.first_name = "Yacine"
        u.last_name = "Petitprez"
        u.save

        u.persisted?.should eq true
        u.notification_preferences = JSON.parse(JSON.build do |json|
          json.object do
            json.field "email", true
          end
        end)
        u.save
      end
    end
  end
end
