require "../spec_helper"
require "./cache_schema"

module CacheSpec
  describe "Clear::Model" do
    temporary do
      Clear::Migration::Manager.instance.reinit!
      MigrateSpec1.new.apply(Clear::Migration::Direction::UP)

      User.create [{id: 101, name: "User 1"}]
      User.create [{id: 102, name: "User 2"}]

      Category.create [{id: 201, name: "Test"}]
      Category.create [{id: 202, name: "Test 2"}]

      Post.create [{id: 301, name: "Post 1", published: true, user_id: 101, category_id: 201, content: "Lorem ipsum"}]
      Post.create [{id: 302, name: "Post 2", published: true, user_id: 102, category_id: 201, content: "Lorem ipsum"}]
      Post.create [{id: 303, name: "Post 2", published: true, user_id: 102, category_id: 202, content: "Lorem ipsum"}]
      Post.create [{id: 304, name: "Post 2", published: true, user_id: 101, category_id: 202, content: "Lorem ipsum"}]

      context "cache system" do
        it "manage has_many relations" do
          Clear::Model::QueryCache.reset_counter
          # relations has_many
          User.query.first!.posts.count.should eq(2)
          User.query.with_posts(&.published.with_category).each do |user|
            Clear::Model::QueryCache.reset_counter
            user.posts.count.should eq(2)
            Clear::Model::QueryCache.cache_hitted.should eq(1)
          end
        end

        it "can be called in chain on the three relations" do
          temporary do
            # Relation belongs_to
            Clear::Model::QueryCache.reset_counter
            Post.query.with_user.each do |post|
              pp post.user.try &.id
            end
            Clear::Model::QueryCache.cache_hitted.should eq(4) # Number of posts

            Category.query.with_users { |q| q.order_by("users.id ASC") }.order_by("id ASC").each do |c|
              c.users.each do |user|
                puts "category = #{c.id}, user = #{user.id}"
              end
            end
          end
        end
      end
    end
  end
end
