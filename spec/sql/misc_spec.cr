require "../spec_helper"

module SQLMiscSpec
  extend self

  @@count = 0_i64

  def self.reinit
    reinit_migration_manager
  end

  describe "Clear::SQL" do
    describe "miscalleanous" do
      it "can truncate a table" do

        begin
          Clear::SQL.execute("CREATE TABLE truncate_tests (id serial PRIMARY KEY, value int)")

          5.times do |x|
            Clear::SQL.insert("truncate_tests", { value: x } ).execute
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