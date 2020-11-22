require "../spec_helper"

module ViewSpec
  describe "Clear::View" do
    it "recreate the views on migration" do
      temporary do
        Clear::View.register :room_per_days do |view|
          view.require(:rooms, :year_days)

          view.query <<-SQL
            SELECT room_id, day
            FROM year_days
            CROSS JOIN rooms
          SQL
        end

        Clear::View.register :rooms do |view|
          view.query <<-SQL
          SELECT room.id as room_id
          FROM generate_series(1, 4) AS room(id)
          SQL
        end

        Clear::View.register :year_days do |view|
          view.query <<-SQL
          SELECT date.day::date as day
          FROM   generate_series(
            date_trunc('day', NOW()),
            date_trunc('day', NOW() + INTERVAL '364 days'),
            INTERVAL '1 day'
          ) AS date(day)
          SQL
        end

        Clear::Migration::Manager.instance.reinit!
        Clear::Migration::Manager.instance.apply_all

        # Ensure than the view is loaded and working properly
        Clear::SQL.select.from("room_per_days").agg("count(day)", Int64).should eq(4*365)
        Clear::View.clear
      end
    end
  end
end
