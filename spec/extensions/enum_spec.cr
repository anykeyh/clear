require "../spec_helper"

module EnumSpec
end

Clear.enum ::EnumSpec::GenderType, "male", "female", "two_part"

module EnumSpec
  extend self

  class EnumMigration18462
    include Clear::Migration

    def change(dir)
      create_enum(:gender_type, GenderType)
      create_enum :other_enum, ["a", "b", "c"]

      create_table(:enum_users) do |t|
        t.string :name
        t.gender_type :gender

        t.timestamps
      end
    end
  end

  class User
    include Clear::Model
    self.table = "enum_users"

    column gender : GenderType?
    column name : String
  end

  def self.reinit!
    reinit_migration_manager
    EnumMigration18462.new.apply(Clear::Migration::Direction::UP)
  end

  describe "Clear::Migration::CreateEnum" do
    it "Can create and use enum" do
      temporary do
        reinit!

        User.create!({name: "Test", gender: GenderType::Male})
        User.create!({name: "Test", gender: GenderType::Female})

        User.query.first!.gender.should eq GenderType::Male
        User.query.offset(1).first!.gender.should eq GenderType::Female

        User.query.first!.gender.should eq "male"
        User.query.offset(1).first!.gender.should eq "female"

        GenderType::TwoPart # < CamelCase ?

        User.query.where { gender == GenderType::Female }.count.should eq 1
        User.query.where { gender == "male" }.count.should eq 1
        User.query.where { gender.in? GenderType.all }.count.should eq 2
      end
    end
  end
end
