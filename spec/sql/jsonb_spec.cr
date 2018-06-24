require "spec"

require "../spec_helper"

module JSONBSpec
  extend self
  extend Clear::SQL::JSONB

  describe "Clear::SQL" do
    describe "JSONB" do
      it "splits string into array of path elements" do
        jsonb_k2a("a.b\\.c.d").should eq(["a", "b.c", "d"])
        jsonb_k2a("\\.a").should eq([".a"])
        jsonb_k2a("").should eq([] of String)
      end

      it "transforms array to hash" do
        jsonb_arr2h(["a", "b"], "c").should eq({"a" => {"b" => "c"}})
        jsonb_arr2h(["a", "b"], 1).should eq({"a" => {"b" => 1}})
      end

      it "can generate arrow writing" do
        jsonb_text("data.x.y.z").should eq("data->'x'->'y'->'z'::text")
        jsonb_text("data.x.\\.y.z").should eq("data->'x'->'.y'->'z'::text")
        jsonb_text("data.x.y'b.z").should eq("data->'x'->'y''b'->'z'::text")
        jsonb_text("data").should eq("data::text")
      end

      it "can use `?|` operator" do
        jsonb_any_exists?("jsonb_column", ["a", "b", "c"]).should eq("jsonb_column ?| array['a','b','c']")
      end

      it "can use `?` operator" do
        jsonb_exists?("jsonb_column", "a").should eq("jsonb_column ? 'a'")
      end

      it "can use `?&` operator" do
        jsonb_all_exists?("jsonb_column", ["a", "b", "c"]).should eq("jsonb_column ?& array['a','b','c']")
      end

      it "can use @> operator" do
        jsonb_eq("data.x.y", "value").should eq("data @> '{\"x\":{\"y\":\"value\"}}'")
        jsonb_eq("data.x.y", 1).should eq("data @> '{\"x\":{\"y\":1}}'")
      end

      it "fits with the expression engine" do
        Clear::SQL.select("*").from("users")
          .where { jsonb_eq("data.security.role", "admin") }.to_sql
          .should eq %(SELECT * FROM users WHERE data @> '{"security":{"role":"admin"}}')

        Clear::SQL.select("*").from("users")
          .where { jsonb_text("data.personal email").like "%@gmail.com" }.to_sql
          .should eq %(SELECT * FROM users WHERE (data->'personal email'::text LIKE '%@gmail.com'))
      end
    end
  end
end
