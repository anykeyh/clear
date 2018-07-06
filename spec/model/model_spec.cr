require "../spec_helper"

module ModelSpec
  class Post
    include Clear::Model

    column id : Int32, primary: true, presence: false

    column title : String

    column tags : Array(String), presence: false
    column flags : Array(Int32), presence: false

    def validate
      ensure_than(title, "is not empty", &.size.>(0))
    end

    belongs_to user : User, key_type: Int32?

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

    column notification_preferences : JSON::Any, presence: false

    has_many posts : Post, foreign_key: "user_id"
    has_one info : UserInfo, foreign_key: "user_id"

    timestamps

    self.table = "model_users"
  end

  class ModelSpecMigration123
    include Clear::Migration

    def change(dir)
      create_table "model_users" do |t|
        t.text "first_name"
        t.text "last_name"
        t.text "middle_name"

        t.jsonb "notification_preferences", index: "gin", default: "'{}'"

        t.timestamps
      end

      create_table "model_user_infos" do |t|
        t.references to: "model_users", name: "user_id", on_delete: "cascade", null: true

        t.int64 "registration_number", index: true

        t.timestamps
      end

      create_table "model_posts" do |t|
        t.string "title", index: true

        t.string "tags", array: true, index: "gin", default: "ARRAY['post', 'arr 2']"
        t.int "flags", array: true, index: "gin", default: "'{}'::int[]"

        t.references to: "model_users", name: "user_id", on_delete: "cascade"
      end
    end
  end

  def self.reinit
    reinit_migration_manager
    ModelSpecMigration123.new.apply(Clear::Migration::Direction::UP)
  end

  describe "Clear::Model" do
    context "fields management" do
      it "can load from tuple" do
        temporary do
          reinit
          u = User.new({id: 123})
          u.id.should eq 123
          u.persisted?.should be_false
        end
      end

      it "can detect persistance" do
        temporary do
          reinit
          u = User.new({id: 1}, persisted: true)
          u.persisted?.should be_true
        end
      end

      it "can detect change in fields" do
        temporary do
          reinit
          u = User.new({id: 1})
          u.id = 2
          u.update_h.should eq({"id" => 2})
          u.id = 1
          u.update_h.should eq({} of String => ::DB::Any) # no more change, because id is back to the same !
        end
      end

      it "should not try to update the model if there's not update" do
        temporary do
          reinit
          u = User.new({id: 1, first_name: "x"})
          u.save!
          u.id = 2
          u.update_h.should eq({"id" => 2})
          u.id = 1
          u.update_h.should eq({} of String => ::DB::Any) # no more change, because id is back to the same !
          u.save!                                         # Nothing should happens
        end
      end

      it "can save the model" do
        temporary do
          reinit
          u = User.new({id: 1, first_name: "x"})
          u.notification_preferences = JSON.parse("{}")
          u.id = 2 # Force the change!
          u.save!
          User.query.count.should eq 1
        end
      end

      it "save in good order the belongs_to models" do
        temporary do
          reinit
          u = User.new
          p = Post.new({title: "some post"})
          p.user = u
          p.save.should eq(false) # < Must save the user first. but user is missing is first name !

          p.user!.first_name = "I fix the issue!" # < Fix the issue

          p.save.should eq(true) # Should save now

          u.id.should eq(1)       # Should be set
          p.user!.id.should eq(1) # And should be set
        end
      end

      it "can save persisted model" do
        temporary do
          reinit
          u = User.new
          u.persisted?.should eq false
          u.first_name = "hello"
          u.last_name = "world"
          u.save!

          u.persisted?.should eq true
          u.id.should eq 1
        end
      end

      it "can load models" do
        temporary do
          reinit
          User.create
          User.query.each do |u|
            u.id.should_not eq nil
          end
        end
      end

      it "can read through cursor" do
        temporary do
          reinit
          User.create
          User.query.each_with_cursor(batch: 50) do |u|
            u.id.should_not eq nil
          end
        end
      end

      it "can fetch computed column" do
        temporary do
          reinit
          User.create({first_name: "a", last_name: "b"})

          u = User.query.select({full_name: "first_name || ' ' || last_name"}).first!(fetch_columns: true)
          u["full_name"].should eq "a b"
        end
      end

      it "define constraints on has_many to build object" do
        temporary do
          reinit
          User.create({first_name: "x"})
          u = User.query.first!
          p = User.query.first!.posts.build

          p.user_id.should eq(u.id)
        end
      end

      it "works on date fields with different timezone" do
        now = Time.now

        temporary do
          reinit

          u = User.new

          u.first_name = "A"
          u.last_name = "B"
          u.created_at = now

          u.save
          u.id.should_not eq nil

          u = User.find! u.id
          u.created_at.epoch.should be_close(now.epoch, 1)
        end
      end

      it "can count using offset and limit" do
        temporary do
          reinit

          9.times do |x|
            User.create!({first_name: "user#{x}"})
          end

          User.query.limit(5).count.should eq(5)
          User.query.limit(5).offset(5).count(Int32).should eq(4)
        end
      end

      it "can find_or_create" do
        temporary do
          reinit

          u = User.query.find_or_create({last_name: "Henry"}) do |user|
            user.first_name = "Thierry"
            user.save
          end

          u.first_name.should eq("Thierry")
          u.last_name.should eq("Henry")
          u.id.should eq(1)

          u = User.query.find_or_create({last_name: "Henry"}) do |user|
            user.first_name = "King" # << This should not be triggered since we found the row
          end
          u.first_name.should eq("Thierry")
          u.last_name.should eq("Henry")
          u.id.should eq(1)
        end
      end

      it "can set back a field to nil" do
        temporary do
          reinit

          u = User.create({first_name: "Rudolf"})

          ui = UserInfo.create({registration_number: 123, user_id: u.id})

          ui.user_id = nil # Remove user_id, just to see what's going on !
          ui.save!
        end
      end

      it "can read and write jsonb" do
        temporary do
          reinit
          u = User.new

          u.first_name = "Yacine"
          u.last_name = "Petitprez"
          pp u.changed?
          u.save.should eq true

          u.notification_preferences = JSON.parse(JSON.build do |json|
            json.object do
              json.field "email", true
            end
          end)
          u.save.should eq true
          u.persisted?.should eq true
        end
      end

      it "can query the last model" do
        temporary do
          reinit
          User.create({first_name: "Yacine"})
          User.create({first_name: "Joan"})
          User.create({first_name: "Mary"})
          User.create({first_name: "Lianna"})

          x = User.query.order_by("first_name").last!
          x.first_name.should eq("Yacine")
        end
      end

      it "can delete a model" do
        temporary do
          reinit

          User.create({first_name: "Malcom", last_name: "X"})

          u = User.new
          u.first_name = "LeBron"
          u.last_name = "James"
          u.save.should eq true

          User.query.count.should eq 2
          u.persisted?.should eq true

          u.delete.should eq true
          u.persisted?.should eq false
          User.query.count.should eq 1
        end
      end
    end

    it "can load a column of type Array" do
      temporary do
        reinit

        u = User.create!({first_name: "John"})
        p = Post.create!({title: "A post", user_id: u.id})

        p.tags = ["a", "b", "c"]
        p.flags = [1, 2, 3, 4]
        p.save!

        p = Post.query.first!
        p.tags.should eq ["a", "b", "c"]
        p.flags.should eq [1, 2, 3, 4]
      end
    end

    context "with join" do
      it "resolves by default ambiguous columns in joins" do
        temporary do
          reinit

          u = User.create!({first_name: "Join User"})

          Post.create!({title: "A Post", user_id: u.id})

          Post.query.join("model_users") { model_posts.user_id == model_users.id }.to_sql
            .should eq "SELECT model_posts.* FROM model_posts INNER JOIN model_users " +
                       "ON ((model_posts.user_id = model_users.id))"
        end
      end

      it "resolve ambiguous columns in with_* methods" do
        temporary do
          reinit
          u = User.create!({first_name: "Join User"})
          Post.create!({title: "A Post", user_id: u.id})

          user_with_a_post_minimum = User.query.distinct.join("model_posts") { model_posts.user_id == model_users.id }

          user_with_a_post_minimum.to_sql.should eq \
            "SELECT DISTINCT model_users.* FROM model_users INNER JOIN " +
            "model_posts ON ((model_posts.user_id = model_users.id))"

          user_with_a_post_minimum.with_posts.each { } # Should just execute
        end
      end
    end

    context "with pagination" do
      it "can pull the next 5 users from page 2" do
        temporary do
          reinit

          15.times do |x|
            User.create!({first_name: "user#{x}"})
          end

          users = User.query.paginate(page: 2, per_page: 5)
          users.map(&.first_name).should eq ["user5", "user6", "user7", "user8", "user9"]
          users.total_entries.should eq 15
        end
      end

      it "can paginate with where clause" do
        temporary do
          reinit
          last_names = ["smith", "jones"]
          15.times do |x|
            last_name = last_names[x % 2]?
            User.create!({first_name: "user#{x}", last_name: last_name})
          end

          users = User.query.where { last_name == "smith" }.paginate(page: 1, per_page: 5)
          users.map(&.first_name).should eq ["user0", "user2", "user4", "user6", "user8"]
          users.total_entries.should eq 8
        end
      end
    end
  end
end
