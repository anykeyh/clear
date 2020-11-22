require "../../spec_helper"

module SelectSpec
  extend self

  describe "SelectQuery#select" do
    it "has default wildcard" do
      Clear::SQL.select.to_sql.should eq(%[SELECT *])
    end

    it "allows simple string" do
      Clear::SQL.select("1").to_sql.should eq(%[SELECT 1])
    end

    it "escapes symbol" do
      Clear::SQL.select(:order).to_sql.should eq(%[SELECT "order"])
    end

    it "allows named tuple" do
      Clear::SQL.select(a: "column_a", b: "column_b")
        .to_sql
        .should eq("SELECT column_a AS a, column_b AS b")
    end

    it "allows named tuple with symbols" do
      Clear::SQL.select(a: :column_a, b: :column_b)
        .to_sql
        .should eq(%[SELECT "column_a" AS a, "column_b" AS b])
    end

    it "allows named tuple mixed in a list of arguments" do
      Clear::SQL.select("id", {max: "MAX(created_at)"})
        .to_sql.should eq("SELECT id, MAX(created_at) AS max")
    end

    it "allows subquery as parameter" do
      subqry = Clear::SQL.select("generate_series(1, 100)")
      Clear::SQL.select(serie: subqry)
        .to_sql
        .should eq(%[SELECT ( SELECT generate_series(1, 100) ) AS serie])
    end

    it "is clearable" do
      qry = Clear::SQL.select("something")

      qry.clear_select.select("something_else")
        .to_sql
        .should eq("SELECT something_else")
    end
  end

  describe "SelectQuery#distinct" do
    it "selects distinct" do
      Clear::SQL.select("id").distinct.to_sql.should eq("SELECT DISTINCT id")
    end

    it "selects distinct on" do
      Clear::SQL.select("users.*").distinct("id").to_sql.should eq("SELECT DISTINCT ON (id) users.*")
    end

    it "clears distinct" do
      qry = Clear::SQL.select("users.*").distinct("id")
      qry.clear_distinct.to_sql.should eq("SELECT users.*")
    end
  end

  describe "SelectQuery#force_select" do
    it "allows simple string" do
      Clear::SQL.select("1").force_select("2").to_sql.should eq(%[SELECT 1, 2])
    end

    it "escapes symbol" do
      Clear::SQL.select.force_select(:order).to_sql.should eq(%[SELECT *, "order"])
    end

    it "allows named tuple" do
      Clear::SQL.select.force_select(a: "column_a", b: "column_b")
        .to_sql
        .should eq("SELECT *, column_a AS a, column_b AS b")
    end

    it "allows named tuple with symbols" do
      Clear::SQL.select.force_select(a: :column_a, b: :column_b)
        .to_sql
        .should eq(%[SELECT *, "column_a" AS a, "column_b" AS b])
    end

    it "is clearable" do
      qry = Clear::SQL.select("something").force_select("something_else")

      qry.clear_select
        .to_sql
        .should eq("SELECT *, something_else")

      qry.clear_force_select
        .to_sql
        .should eq("SELECT *")
    end
  end
end
