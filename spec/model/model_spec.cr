require "../spec_helper"

module ModelSpec
  class Post
    include Clear::Model

    column id : Int32, primary: true, presence: false

    column title : String?

    belongs_to user : User

    self.table = "models_posts"
  end

  class UserInfo
    include Clear::Model

    column id : Int32, primary: true, presence: false

    belongs_to user : User
    column registration_number : Int64

    self.table = "model_user_infos"
  end

  class User
    include Clear::Model

    column id : Int32, primary: true, presence: false

    column first_name : String?
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

        t.jsonb "notification_preferences", index: "gin", default: Clear::Expression["{}"]

        t.timestamps
      end

      create_table "model_user_infos" do |t|
        t.references to: "model_users", name: "user_id", on_delete: "cascade"

        t.int64 "registration_number", index: true

        t.timestamps
      end

      create_table "models_posts" do |t|
        t.string "title", index: true
        t.references to: "model_users", name: "user_id", on_delete: "cascade"
      end
    end
  end

  def self.reinit
    Clear::Migration::Manager.instance.reinit!
    ModelSpecMigration123.new.apply(Clear::Migration::Direction::UP)
  end

  describe "Clear::Model" do
    context "fields management" do
      it "can load from array" do
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

      it "can save the model" do
        temporary do
          reinit
          u = User.new({id: 1})
          u.notification_preferences = JSON.parse("{}")
          u.id = 2 # Force the change!
          u.save!
          User.query.count.should eq 1
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

      it "define constraints on has_many to build object" do
        temporary do
          reinit
          User.create
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
          u.created_at.epoch.should eq(now.epoch)
        end
      end

      it "can find_or_create" do
        temporary do
          reinit

          u = User.query.find_or_create({last_name: "Henry"}) do |u|
            u.first_name = "Thierry"
            u.save
          end

          u.first_name.should eq("Thierry")
          u.last_name.should eq("Henry")
          u.id.should eq(1)

          u = User.query.find_or_create({last_name: "Henry"}) do |u|
            u.first_name = "King" #<< This should not be triggered since we found the row
          end
          u.first_name.should eq("Thierry")
          u.last_name.should eq("Henry")
          u.id.should eq(1)
        end
      end

      it "can read and write jsonb" do
        temporary do
          reinit
          u = User.new

          u.first_name = "Yacine"
          u.last_name = "Petitprez"
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
  end
end
