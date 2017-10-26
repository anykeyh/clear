require "spec"

require "../src/clear/model"

module ModelSpec
  class User
    include Clear::Model

    before(:save) { |u| puts "hello world!" }

    field(id : Int32, primary: true)

    field(first_name : String)
    field(last_name : String)
    field(middle_name : String?)

    field(notification_preferences : JSON::Any?)

    timestamps

    self.table = "users"
  end

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
        u = User.new({id: 1}, persisted: true)
        u.id = 2 # Force the change!
        u.save
      end

      it "can load models" do
        User.query.each do |user|
          pp user.first_name
        end
      end

      it "can read through cursor" do
        User.query.each_with_cursor(batch: 50) do |user|
          pp user.first_name
        end
      end

      it "can read json" do
        pp User.query.first!.notification_preferences
      end
    end
  end
end
