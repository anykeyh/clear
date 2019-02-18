require "../spec_helper"

module IntervalSpec

  class IntervalMigration78392
    include Clear::Migration

    def change(dir)
      create_table(:interval_table) do |t|
        t.column :i, :interval, null: false

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

    column i : Clear::SQL::Interval
  end

  describe Clear::SQL::Interval do
    it "Can be saved into database (and converted to pg interval type)" do
      temporary do
        reinit!

        3.times do |x|
          mth = Random.rand(-1000..1000)
          days = Random.rand(-1000..1000)
          microseconds = Random.rand(-10000000..10000000)

          IntervalModel.create id: x, i: Clear::SQL::Interval.new(months: mth, days: days, microseconds: microseconds)

          mdl = IntervalModel.find! x
          mdl.i.months.should eq mth
          mdl.i.days.should eq days
          mdl.i.microseconds.should eq microseconds
        end

      end
    end
  end


end