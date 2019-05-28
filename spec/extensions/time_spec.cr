require "../spec_helper"

module IntervalSpec

  class IntervalMigration78392
    include Clear::Migration

    def change(dir)
      create_table(:interval_table) do |t|
        t.column :i, :interval, null: false
        t.column :t, :time, null: true

        t.timestamps
      end
    end
  end

  def self.reinit!
    reinit_migration_manager
    IntervalMigration78392.new.apply(Clear::Migration::Direction::UP)
  end

  class IntervalModel
    include Clear::Model

    primary_key

    self.table = "interval_table"

    column i : Clear::Interval
    column t : Clear::TimeInDay?
  end

  describe Clear::Interval do
    it "Can be saved into database (and converted to pg interval type)" do
      temporary do
        reinit!

        3.times do |x|
          mth = Random.rand(-1000..1000)
          days = Random.rand(-1000..1000)
          microseconds = Random.rand(-10000000..10000000)

          IntervalModel.create! id: x, i: Clear::Interval.new(months: mth, days: days, microseconds: microseconds)

          mdl = IntervalModel.find! x
          mdl.i.months.should eq mth
          mdl.i.days.should eq days
          mdl.i.microseconds.should eq microseconds
        end

      end
    end

    it "can be added and substracted to a date" do

      # TimeSpan
      [1.hour, 1.day, 1.month].each do |span|
        i = Clear::Interval.new(span)
        now = Time.now

        (now + i).to_unix.should eq( (now+span).to_unix)
        (now - i).to_unix.should eq( (now-span).to_unix )
      end

      i = Clear::Interval.new(months: 1, days: -1, minutes: 12)
      now = Time.now

      (now + i).to_unix.should eq( (now+1.month-1.day+12.minute).to_unix)
      (now - i).to_unix.should eq( (now-1.month+1.day-12.minute).to_unix)

    end

    it "can be used in expression engine" do
      IntervalModel.query.where{
        (created_at - Clear::Interval.new(months: 1)) > updated_at
      }.to_sql.should eq %(SELECT * FROM "interval_table" WHERE (("created_at" - INTERVAL '1 months') > "updated_at"))
    end

    it "can be casted into string" do
      Clear::Interval.new(months: 1, days: 1).to_sql.to_s.should eq("INTERVAL '1 months 1 days'")
    end
  end

  describe Clear::TimeInDay do
    it "can be parsed" do
      value = 12i64 * 3_600 + 50*60
      Clear::TimeInDay.parse("12:50").microseconds.should eq(value * 1_000_000)

      Clear::TimeInDay.parse("12:50:02").microseconds.should eq( (value+2)  * 1_000_000)

      wrong_formats = {"a:21", ":32:54", "12345", "0:0:0" }

      wrong_formats.each do |format|
        expect_raises(Exception, /wrong format/i){ Clear::TimeInDay.parse(format) }
      end

    end

    it "can be saved into database and converted" do
      temporary do
        reinit!

        i = IntervalModel.create! i: Clear::Interval.new(days: 1), t: "12:32"
        i.t.not_nil!.to_s(show_seconds: false).should eq("12:32")
        i.t = i.t.not_nil! + 12.minutes
        i.save!
      end

    end
  end

end