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
        jsonb_resolve("data", "x.y.z").should eq("data->'x'->'y'->>'z'")
        jsonb_resolve("data", "x.\\.y.z").should eq("data->'x'->'.y'->>'z'")
        jsonb_resolve("data", "x.y'b.z").should eq("data->'x'->'y''b'->>'z'")
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
        jsonb_eq("data", "x.y", "value").should eq("data @> '{\"x\":{\"y\":\"value\"}}'")
        jsonb_eq("data", "x.y", 1).should eq("data @> '{\"x\":{\"y\":1}}'")
      end

      describe "Expression engine" do
        it "use -> operator when it cannot test presence" do
          Clear::SQL.select("*").from("users")
            .where { data.jsonb("personal email").like "%@gmail.com" }.to_sql
            .should eq %(SELECT * FROM users WHERE (data->>'personal email' LIKE '%@gmail.com'))

          # v-- Usage of 'raw' should trigger usage of arrow, since it's not a literal.
          Clear::SQL.select.from("users")
            .where { data.jsonb("test") == raw("afunction()") }.to_sql
            .should eq %(SELECT * FROM users WHERE (data->>'test' = afunction()))
        end

        it "merges the jsonb instructions (optimization)" do
          Clear::SQL.select("*").from("users")
            .where {
              (data.jsonb("security.role") == "admin") &
                (data.jsonb("security.level") == 1)
            }.to_sql
            .should eq "SELECT * FROM users WHERE (data @> '{\"security\":{\"role\":\"admin\"}}') OR " +
                       "(data @> '{\"security\":{\"role\":1}}')"
        end
      end
    end
  end
end
