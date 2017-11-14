require "spec"

require "../src/clear/sql"

module InsertSpec
  extend self

  def insert_request
    Clear::SQL::InsertQuery.new(:users)
  end

  describe "Clear::SQL" do
    describe "InsertQuery" do
      it "can build an insert" do
        insert_request.insert({a: "c", b: 12}).to_sql.should eq(
          "INSERT INTO users (a, b) VALUES ('c', 12)"
        )
      end

      it "can build an insert from sql" do
        insert_request.values(
          Clear::SQL.select.from("old_users")
                           .where { old_users.id > 100 }
        ).to_sql.should eq (
          "INSERT INTO users (SELECT * FROM old_users WHERE (old_users.id > 100))"
        )
      end

      it "can build an empty insert?" do
        insert_request.to_sql.should eq (
          "INSERT INTO users DEFAULT VALUES"
        )
      end
    end
  end
end
