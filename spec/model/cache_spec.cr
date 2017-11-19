require "../spec_helper"
require "./cache_schema"

module CacheSpec
  describe "Clear::Model" do
    temporary do
      MigrateSpec1.new.apply(Clear::Migration::Direction::UP)

      context "cache system" do
        it "can be called in chain on the three relations" do
          temporary do
            User.create [{id: 101, name: "User 1"}]
            User.create [{id: 102, name: "User 2"}]

            Category.create [{id: 201, name: "Test"}]
            Category.create [{id: 202, name: "Test 2"}]

            Post.create [{id: 301, name: "Post 1", published: true, user_id: 101, category_id: 201, content: "Lorem ipsum"}]
            Post.create [{id: 302, name: "Post 2", user_id: 102, category_id: 201, content: "Lorem ipsum"}]
            Post.create [{id: 303, name: "Post 2", user_id: 102, category_id: 202, content: "Lorem ipsum"}]
            Post.create [{id: 304, name: "Post 2", user_id: 101, category_id: 202, content: "Lorem ipsum"}]

            # I really don't know how to assert on the cache from here.
            # Maybe I should monkey patch the cache system to count
            # the miss and hit stats?
            # For now I'm checking manually if the output is correct...
            User.query.with_posts { |c| c.published.with_category }.each do |user|
              user.posts.map(&.category.try(&.name))
            end

            # Relation has_one
            Post.query.with_user.each do |post|
              pp post.user.try &.id
            end

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
