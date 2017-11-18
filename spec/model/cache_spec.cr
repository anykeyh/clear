require "../spec_helper"

require "./cache_schema"

module CacheSpec
  def self.init
  end

  describe "Clear::Model" do
    context "cache system" do
      it "can be called in chain on the three relations" do
        temporary do
          User.create [{id: 1, name: "User 1"}]
          User.create [{id: 2, name: "User 2"}]

          Category.create [{id: 1, name: "Test"}]

          Post.create [{id: 1, name: "Post 1", published: true, user_id: 1, category_id: 1, content: "Lorem ipsum"}]
          Post.create [{id: 2, name: "Post 2", user_id: 2, category_id: 1, content: "Lorem ipsum"}]

          # I really don't know how to assert on the cache from here.
          # Maybe I should monkey patch the cache system to count
          # the miss and hit stats?
          # For now I'm checking manually if the output is correct...
          User.query.with_posts { |c| c.published.with_category }.each do |user|
            user.posts.map(&.category.try(&.name))
          end

          # Relation has_one
          puts "has_one"
          Post.query.with_user.each do |post|
            pp post.user.try &.id
          end

          c = Category.query.first!
          pp c.users.map &.to_s
        end
      end
    end
  end
end
