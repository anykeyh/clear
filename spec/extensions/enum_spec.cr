require "../spec_helper"

module EnumSpec
  extend self

  Clear.enum GenderType, "male", "female", "both"
  Clear.enum ClientType, "company", "non_profit", "personnal" do
    def pay_vat?
      self == Personnal
    end
  end

  class EnumMigration18462
    include Clear::Migration

    def change(dir)
      create_enum(:gender_type, GenderType)
      create_enum :other_enum, ["a", "b", "c"]

      create_table(:enum_users) do |t|
        t.column :name, :string
        t.column :gender, :gender_type

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
    EnumMigration18462.new.apply
  end

  describe "Clear.enum" do
    it "can call custom member methods" do
      ClientType::Personnal.pay_vat?.should eq true
      ClientType::Company.pay_vat?.should eq false
      ClientType::NonProfit.pay_vat?.should eq false
    end

    it "Can create and use enum" do
      temporary do
        reinit!

        User.create!({name: "Test", gender: GenderType::Male})
        User.create!({name: "Test", gender: GenderType::Female})

        User.query.first!.gender.should eq GenderType::Male
        User.query.offset(1).first!.gender.should eq GenderType::Female

        User.query.first!.gender.should eq "male"
        User.query.offset(1).first!.gender.should eq "female"

        User.query.where { gender == GenderType::Female }.count.should eq 1
        User.query.where { gender == "male" }.count.should eq 1
        User.query.where { gender.in? GenderType.all }.count.should eq 2
      end
    end

    it "can export to json" do
      temporary do
        reinit!

        User.create!({name: "Test", gender: GenderType::Male})
        u = User.query.first!
        u.to_json.should eq %<{"gender":"male","name":"Test"}>
      end
    end
  end
end
