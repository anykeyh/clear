require "../../spec_helper"

module PaginationSpec
  describe Clear::SQL::Query::WithPagination do
    context "when there's 1901902 records and limit of 25" do
      it "sets the per_page to 25" do
        r = Clear::SQL.select.from(:users).offset(0).limit(25)
        r.total_entries = 1_901_902_i64
        r.per_page.should eq 25
      end

      it "returns 1 for current_page with no limit set" do
        r = Clear::SQL.select.from(:users)
        r.total_entries = 1_901_902_i64
        r.current_page.should eq 1
      end

      it "returns 5 for current_page when offset is 100" do
        r = Clear::SQL.select.from(:users).offset(100).limit(25)
        r.total_entries = 1_901_902_i64
        r.current_page.should eq 5
      end

      it "returns 1 for total_pages when there's no limit" do
        r = Clear::SQL.select.from(:users)
        r.total_entries = 1_901_902_i64
        r.total_pages.should eq 1
      end

      it "returns 76077 total_pages when 25 per_page" do
        r = Clear::SQL.select.from(:users).offset(100).limit(25)
        r.total_entries = 1_901_902_i64
        r.total_pages.should eq 76_077
      end

      it "returns 4 as previous_page when on page 5" do
        r = Clear::SQL.select.from(:users).offset(100).limit(25)
        r.total_entries = 1_901_902_i64
        r.current_page.should eq 5
        r.previous_page.should eq 4
      end

      it "returns nil for previous_page when on page 1" do
        r = Clear::SQL.select.from(:users).offset(0).limit(25)
        r.total_entries = 1_901_902_i64
        r.current_page.should eq 1
        r.previous_page.should eq nil
      end

      it "returns 6 as next_page when on page 5" do
        r = Clear::SQL.select.from(:users).offset(100).limit(25)
        r.total_entries = 1_901_902_i64
        r.current_page.should eq 5
        r.next_page.should eq 6
      end

      it "returns nil for next_page when on page 76077" do
        r = Clear::SQL.select.from(:users).offset(1_901_900).limit(25)
        r.total_entries = 1_901_902_i64
        r.current_page.should eq 76_077
        r.next_page.should eq nil
      end

      it "returns true for out_of_bounds? when current_page is 76078" do
        r = Clear::SQL.select.from(:users).offset(1_901_925).limit(25)
        r.total_entries = 1_901_902_i64
        r.current_page.should eq 76_078
        r.out_of_bounds?.should eq true
      end

      it "returns false for out_of_bounds? when current_page is in normal range" do
        r = Clear::SQL.select.from(:users).offset(925).limit(25)
        r.total_entries = 1_901_902_i64
        r.out_of_bounds?.should eq false
      end
    end
  end
end
