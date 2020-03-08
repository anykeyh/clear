require "spec"

require "../../spec_helper"

module SelectSpec
  extend self

  describe "SelectQuery#select" do
    it "has default wildcard" do
      Clear::SQL.select.to_sql.should eq(%[SELECT *])
      Clear::SQL.select("1").to_sql.should eq(%[SELECT 1])
    end
  end
end