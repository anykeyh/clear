require "../../spec_helper"
require "./fixture"

module RelationSpec

  describe("has_one relation (not nilable)") do
    it "can access" do
      temporary do
        reinit_migration_manager
        RelationMigration8001.new.apply

        UserInfo.create!(
          user: User.create!(first_name: "relation_user"),
          infos: "anything"
        )

        user = User.query.first!

        user.user_info.infos.should eq("anything")
      end
    end
  end

  it "throw error if not found" do
    temporary do
      reinit_migration_manager
      RelationMigration8001.new.apply

      User.create!(id: 1000, first_name: "relation_user")

      expect_raises(Exception) do
        UserInfo.create!(id: 2000, user_id: nil, infos: "anything") # Bad id
        user = User.query.first!
        user.user_info
      end
    end
  end

  it "set the id of the related model after save on persistence" do
    temporary do
      reinit_migration_manager
      RelationMigration8001.new.apply

      user = User.new({id: 1000, first_name: "relation_user"})
      user_info = UserInfo.new({id: 2000, infos: "bla"})

      user.persisted?.should be_false

      user.user_info = user_info
      user.persisted?.should be_true

      user_info.user.should eq(user)
    end
  end


  it "raises an exception if the model is not persisted and cannot be saved" do
    temporary do
      reinit_migration_manager
      RelationMigration8001.new.apply

      user = User.new({id: 1000})
      user_info = UserInfo.new({id: 2000, infos: "bla"})

      user.persisted?.should be_false

      expect_raises(Exception) do
        user.user_info = user_info
      end

      user.errors.size.should eq(1)
    end
  end

  it "can avoid n+1 queries" do
    temporary do
      reinit_migration_manager
      RelationMigration8001.new.apply

      users = {
        User.create!(id: 1000, first_name: "relation_user"),
        User.create!(id: 1001, first_name: "relation_user")
      }

      5.times do |x|
        UserInfo.create!(id: (2000 + x), user: users.sample, infos: "#{x}")
      end

      user_info_call = 0
      user_call = 0

      query1 = User.query.before_query{ user_call+=1 }
      query1.with_user_info{ user_info_call += 1 }

      query1.each do |user|
        user_info_call.should eq(1)
        user_call.should eq(1)

        # FIXME: Not sure how to check if there's queries made here.
        #        for now we assume there's none :-)
        user.user_info
      end
    end
  end
end
