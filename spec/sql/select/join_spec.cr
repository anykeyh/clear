require "../../spec_helper"

module JoinSpec
  extend self

  describe "Clear::SQL::Query::Join" do
    it "constructs a INNER JOIN using expression engine" do
      Clear::SQL.select.from(:posts).inner_join(:users) { users.id == posts.user_id }
        .to_sql.should eq(%[SELECT * FROM "posts" INNER JOIN "users" ON ("users"."id" = "posts"."user_id")])
    end

    it "constructs a INNER JOIN using simple string condition" do
      Clear::SQL.select.from("posts").inner_join("users", "users.id = posts.user_id")
        .to_sql.should eq(%[SELECT * FROM posts INNER JOIN users ON (users.id = posts.user_id)])
    end

    it "constructs a LATERAL LEFT JOIN using expression engine" do
      Clear::SQL.select.from("posts").left_join(Clear::SQL.select("1"), lateral: true)
        .to_sql.should eq(%[SELECT * FROM posts LEFT JOIN LATERAL (SELECT 1) ON (true)])
    end

    it "constructs all common type of joins" do
      # Just ensure it is callable.
      {% for join in [:left, :inner, :right, :full_outer, :cross] %}
        Clear::SQL.select.from("posts").{{join.id}}_join("users")
      {% end %}
    end
  end
end
