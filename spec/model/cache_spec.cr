require "../spec_helper"

require "./cache_schema"

module CacheSpec
  def self.init
  end

  describe "Clear::Model" do
    context "cache system" do
      it "can be stacked on N+1" do
        temporary do
          User.create [{id: 1, name: "User 1"}]
          User.create [{id: 2, name: "User 2"}]

          Category.create [{id: 1, name: "Test"}]

          Post.create [{id: 1, name: "Post 1", published: true, user_id: 1, category_id: 1, content: "Lorem ipsum"}]
          Post.create [{id: 2, name: "Post 2", user_id: 2, category_id: 1, content: "Lorem ipsum"}]

          User.query.with_posts { |c| c.published.with_category }.each do |user|
            # ... should use the cache.
            print "posts for user #{user.name}: "
            puts user.posts.map(&.category.try(&.name))
          end
        end
      end
    end
  end
end
