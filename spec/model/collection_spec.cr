require "../spec_helper"
require "../data/example_models"


module CollectionSpec
  describe Clear::Model::CollectionBase do
    it "[] / []?" do
      temporary do
        reinit_example_models

        10.times do |x|
          User.create! first_name: "user #{x}"
        end

        qry = User.query.order_by(:first_name, :asc)

        qry[1].first_name.should eq("user 1")
        qry[3..5].map(&.first_name).should eq(["user 3", "user 4"])

        qry[2]?.not_nil!.first_name.should eq("user 2")
        qry[10]?.should be_nil
      end
    end

    it "find / find!" do
      temporary do
        reinit_example_models

        10.times do |x|
          User.create! first_name: "user #{x}"
        end

        User.query.find{ first_name == "user 2" }.not_nil!.first_name.should eq("user 2")
        User.query.find{ first_name == "not_exists" }.should be_nil

        expect_raises(Clear::SQL::RecordNotFoundError) {
          User.query.find!{ first_name == "not_exists" }
        }
      end
    end

    it "first_or_create" do
      temporary do
        reinit_example_models

        10.times do |x|
          User.create! first_name: "user #{x}"
        end

        # already existing stuff
        User.query.where(first_name: "user 1").count.should eq(1)
        rec = User.query.find_or_create(first_name: "user 1") do
          raise "Should not initialize the model"
        end

        rec.persisted?.should be_true
        User.query.where(first_name: "user 1").count.should eq(1)

        User.query.where(first_name: "not_exist").count.should eq(0)
        rec = User.query.find_or_create(first_name: "not_exist") do |usr|
          usr.last_name = "now_it_exists"
        end
        rec.persisted?.should be_true
        User.query.where(last_name: "now_it_exists").count.should eq(1)

        # with @tags metadata of the collection it should infer the where clause
        usr = User.query.where(first_name: "Sarah", last_name: "Connor").find_or_create
        usr.persisted?.should be_true
        usr.first_name.should eq("Sarah")
        usr.last_name.should eq("Connor")
      end
    end

    pending "first_or_build" do
    end


    pending "first" do
    end

    pending "last" do
      # last, last!, last(fetch_columns)
    end

    pending "delete_all" do
    end
  end
end