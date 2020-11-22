require "../spec_helper"

module SQLMiscSpec
  extend self

  @@count = 0_i64

  def self.reinit
    reinit_migration_manager
  end

  describe "Clear::SQL" do
    describe "miscalleanous" do
      it "can escape for SQL-safe object" do
        Clear::SQL.escape("order").should eq "\"order\""
        Clear::SQL.escape("").should eq "\"\""
        Clear::SQL.escape(:hello).should eq "\"hello\""

        Clear::SQL.escape("some.weird.column name").should eq "\"some.weird.column name\""
        Clear::SQL.escape("\"hello world\"").should eq "\"\"\"hello world\"\"\""
      end

      it "can sanitize for SQL-safe string" do
        Clear::SQL.sanitize(1).should eq "1"
        Clear::SQL.sanitize("").should eq "''"
        Clear::SQL.sanitize(nil).should eq "NULL"
        Clear::SQL.sanitize("l'hotel").should eq "'l''hotel'"
      end

      it "can create SQL fragment" do
        Clear::SQL.raw("SELECT * FROM table WHERE x = ?", "hello").should eq(
          %(SELECT * FROM table WHERE x = 'hello')
        )

        Clear::SQL.raw("SELECT * FROM table WHERE x = :x", x: 1).should eq(
          %(SELECT * FROM table WHERE x = 1)
        )
      end

      it "can truncate a table" do
        begin
          Clear::SQL.execute("CREATE TABLE truncate_tests (id serial PRIMARY KEY, value int)")

          5.times do |x|
            Clear::SQL.insert("truncate_tests", {value: x}).execute
          end

          count = Clear::SQL.select.from("truncate_tests").count
          count.should eq 5

          # Truncate the table
          Clear::SQL.truncate("truncate_tests")
          count = Clear::SQL.select.from("truncate_tests").count
          count.should eq 0
        ensure
          Clear::SQL.execute("DROP TABLE truncate_tests;")
        end
      end
    end
  end
end
