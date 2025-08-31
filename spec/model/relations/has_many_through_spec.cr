require "../../spec_helper"
require "./fixture_spec"

module RelationSpec
  describe("has_many relation (not nilable)") do
    it "can access" do
      temporary do
        reinit_migration_manager
        RelationMigration8001.new.apply

        u = User.create!(first_name: "yacine")
        p = Post.create!(content: "something", user: u)

        c1 = Category.create!(name: "Tech")
        c2 = Category.create!(name: "Health")

        PostCategory.create!(post: p, category: c1)
        PostCategory.create!(post: p, category: c2)

        c1.posts.count.should eq(1)
        p.categories.order_by("name", :asc).pluck_col(:name).join(", ").should eq("Health, Tech")

        u.categories.count.should eq 2
      end
    end
  end

  it "throw error if not found" do
    temporary do
      reinit_migration_manager
      RelationMigration8001.new.apply

      User.create!(id: 1000, first_name: "relation_user")

      UserInfo.create!(id: 2000, user_id: nil, infos: "anything") # No users
      user = User.query.first!
      user.user_infos.count.should eq(0)
    end
  end

  it "set the id of the related model after save on persistence" do
    temporary do
      reinit_migration_manager
      RelationMigration8001.new.apply

      user = User.new({id: 1000, first_name: "relation_user"})
      user_info = UserInfo.new({id: 2000, infos: "bla"})

      user.persisted?.should be_false

      user.user_infos << user_info
      user.persisted?.should be_true

      user_info.user.should eq(user)
      user.user_infos.count.should eq(1)
    end
  end

  it "raises an exception if the model is not persisted and cannot be saved" do
    temporary do
      reinit_migration_manager
      RelationMigration8001.new.apply

      user = User.new({id: 1000})
      user_info = UserInfo.new({id: 2000, infos: "bla"})

      user.persisted?.should be_false

      expect_raises(Exception, /first_name: must be present/) do
        user.user_infos << user_info
      end

      user.first_name = "José"
      user.user_infos << user_info
      user.reload.user_infos.count.should eq(1)
    end
  end

  it "can avoid n+1 queries" do
    temporary do
      reinit_migration_manager
      RelationMigration8001.new.apply

      u = User.create!(first_name: "yacine")
      p = Post.create!(content: "something", user: u)

      c1 = Category.create!(name: "Tech")
      c2 = Category.create!(name: "Health")

      PostCategory.create!(post: p, category: c1)
      PostCategory.create!(post: p, category: c2)

      category_call = 0
      user_call = 0

      query1 = User.query.before_query { user_call += 1 }
      query1.with_categories { category_call += 1 }

      query1.each do |user|
        category_call.should eq 1
        user_call.should eq 1

        # FIXME: Not sure how to check if there's queries made here.
        #        for now we assume there's none :-)

        user.categories.count.should eq 2 # 2 for each
      end
    end
  end

  it "passes through belongs_to association" do
    temporary do
      reinit_migration_manager
      RelationMigration8001.new.apply

      users = {
        User.create!(id: 1000, first_name: "relation_user1"),
        User.create!(id: 1001, first_name: "relation_user2"),
      }

      2.times do |x|
        UserInfo.create!(id: (2000 + x), user: users[x % users.size], infos: "#{x}")
      end

      c1 = Category.create!(name: "Tech")
      p = Post.create!(content: "This is a post", user: users[0])

      PostCategory.create!(post: p, category: c1)

      Post.query.first!.user_infos.count.should eq(1)
    end
  end
end
