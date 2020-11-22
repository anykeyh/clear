require "../../spec_helper"

module FromSpec
  extend self

  describe Clear::SQL::Query::From do
    it "allows simple string" do
      Clear::SQL.select.from("users").to_sql.should eq("SELECT * FROM users")
    end

    it "escapes symbols" do
      Clear::SQL.select.from(:orders).to_sql.should eq(%[SELECT * FROM "orders"])
    end

    it "accepts named tuple" do
      Clear::SQL.select.from(clients: "users").to_sql.should eq("SELECT * FROM users AS clients")
      Clear::SQL.select.from(clients: :users).to_sql.should eq(%[SELECT * FROM "users" AS clients])
    end

    it "accepts subquery" do
      subquery = Clear::SQL.select("generate_series(1, 100, 1)")
      Clear::SQL.select.from(series: subquery).to_sql.should eq("SELECT * FROM (SELECT generate_series(1, 100, 1)) series")
    end

    it "accepts multiple from clauses" do
      r = Clear::SQL.select.from(:users, :posts)
      r.to_sql.should eq "SELECT * FROM \"users\", \"posts\""
    end

    it "stacks" do
      r = Clear::SQL.select.from("x").from(:y)
      r.to_sql.should eq "SELECT * FROM x, \"y\""
    end

    it "raises error if the from clause is a subquery but is not aliased" do
      expect_raises Clear::SQL::QueryBuildingError do
        r = Clear::SQL.select.from(Clear::SQL.select("1"))
        r.to_sql
      end
    end

    it "can be cleared" do
      r = Clear::SQL.select.from("x").clear_from.from("y")
      r.to_sql.should eq "SELECT * FROM y"
    end
  end
end
