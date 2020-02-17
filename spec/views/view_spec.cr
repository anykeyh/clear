require "../spec_helper"

module ViewSpec

  def self.view_date
    <<-SQL
      SELECT date.day::date as day
      FROM   generate_series(
        date_trunc('day', NOW()),
        date_trunc('day', NOW() + INTERVAL '365 days'),
        INTERVAL '1 day'
      ) AS date(day);
    SQL
  end

  describe "Clear::View" do
    it "recreate the views on migration" do
      temporary do
        Clear::View.register do |view|
          view.name "year_days"
          view.query view_date
        end

        Clear::Migration::Manager.instance.reinit!
        Clear::Migration::Manager.instance.apply_all

        # Ensure than the view is loaded and working properly
        Clear::SQL.select.from("year_days").agg("count(day)", Int64).should eq(366)
        Clear::View.clear
      end
    end

  end

end