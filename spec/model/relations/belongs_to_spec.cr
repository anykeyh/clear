require "../../spec_helper"
require "./fixture_spec"

module RelationSpec
  describe("belongs_to relation (not nilable)") do
    it "can access" do
      temporary do
        reinit_migration_manager
        RelationMigration8001.new.apply

        u = User.create!(id: 1000, first_name: "relation_user")
        UserInfo.create!(id: 2000, user: u, infos: "anything")

        uinfo = UserInfo.query.first!

        uinfo.user!.first_name.should eq("relation_user")
      end
    end

    it "throw error if not found" do
      temporary do
        reinit_migration_manager
        RelationMigration8001.new.apply

        User.create!(id: 1000, first_name: "relation_user")

        expect_raises(Exception) do
          UserInfo.create!(id: 2000, user_id: nil, infos: "anything") # Bad id
          uinfo = UserInfo.query.first!
          uinfo.user! # Not found
        end
      end
    end

    it "saves model before saving itself if associated model is not persisted" do
      temporary do
        reinit_migration_manager
        RelationMigration8001.new.apply

        user = User.new({id: 1000, first_name: "relation_user"})
        user_info = UserInfo.new({id: 2000, user: user, infos: "bla"})

        user_info.save!
        user_info.persisted?.should be_true
        user.persisted?.should be_true
      end
    end

    it "fails to save if the associated model is incorrect" do
      temporary do
        reinit_migration_manager
        RelationMigration8001.new.apply

        user = User.new({id: 1000}) # > No first_name field
        user_info = UserInfo.new({id: 2000, user: user, infos: "bla"})

        user_info.save.should be_false
        user_info.errors.size.should eq(1)
        user_info.errors[0].reason.should eq("first_name: must be present")

        # error correction
        user.first_name = "Luis"
        user_info.save.should be_true
      end
    end

    it "can avoid n+1 queries" do
      temporary do
        reinit_migration_manager
        RelationMigration8001.new.apply

        users = {User.create!(id: 1000, first_name: "relation_user"),
                 User.create!(id: 1001, first_name: "relation_user")}

        5.times do |x|
          UserInfo.create!(id: (2000 + x), user: users.sample, infos: "#{x}")
        end

        user_info_call = 0
        user_call = 0

        query1 = UserInfo.query.before_query { user_info_call += 1 }
        query1.with_user { user_call += 1 }

        query1.each do |user_info|
          user_info_call.should eq(1)
          user_call.should eq(1)

          # FIXME: Not sure how to check if there's queries made here.
          #        for now we assume there's none :-)
          user_info.user
        end
      end
    end
  end
end
