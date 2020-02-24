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
        jsonb_resolve("data", "x.y.z").should eq("data->'x'->'y'->'z'")
        jsonb_resolve("data", "x.\\.y.z").should eq("data->'x'->'.y'->'z'")
        jsonb_resolve("data", "x.y'b.z", "text").should eq("(data->'x'->'y''b'->'z')::text")
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
            .where { data.jsonb("personal email").cast("text").like "%@gmail.com" }.to_sql
            .should eq %(SELECT * FROM users WHERE (("data"->'personal email')::text LIKE '%@gmail.com'))

          # v-- Complex call
          Clear::SQL.select.from("users")
            .where { data.jsonb("test") == call_function(data.jsonb("a.b.c")) }.to_sql
            .should eq %(SELECT * FROM users WHERE ("data"->'test' = call_function("data"->'a'->'b'->'c')))
        end

        it "uses @> operator when it can !" do
          Clear::SQL.select("*").from(:users)
            .where {
              (data.jsonb("security.role") == "admin") &
                (data.jsonb("security.level") == 1)
            }.to_sql
            .should eq "SELECT * FROM \"users\" WHERE (\"data\" @> '{\"security\":{\"role\":\"admin\"}}' AND " +
                       "\"data\" @> '{\"security\":{\"level\":1}}')"
        end

        it "check existence of a key" do
          Clear::SQL.select.from(:users)
            .where { data.jsonb_key_exists?("test") }
            .to_sql
            .should eq "SELECT * FROM \"users\" WHERE (\"data\" ? 'test')"

          Clear::SQL.select.from("users")
            .where { data.jsonb("a").jsonb_key_exists?("test") }
            .to_sql
            .should eq "SELECT * FROM users WHERE (\"data\"->'a' ? 'test')"
        end

        it "check existence of any key" do
          Clear::SQL.select.from(:users)
            .where { data.jsonb_any_key_exists?(["a", 0]) }
            .to_sql
            .should eq "SELECT * FROM \"users\" WHERE (\"data\" ?| array['a', 0])"
        end

        it "check existence of all keys" do
          Clear::SQL.select.from("users")
            .where { data.jsonb("a").jsonb_all_keys_exists?(["a", "b"]) }
            .to_sql
            .should eq "SELECT * FROM users WHERE (\"data\"->'a' ?& array['a', 'b'])"
        end
      end
    end
  end
end
