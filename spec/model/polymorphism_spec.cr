require "../spec_helper"

module PolymorphismSpec
  abstract class AbstractClass
    include Clear::Model

    self.table = "polymorphs"

    polymorphic ConcreteClass1,
      ConcreteClass2,
      through: "type"

    column common_value : Int32?

    abstract def print_value : String
  end

  # Non-polymorphic model
  class OtherModel
    include Clear::Model
  end

  class ConcreteClass1 < AbstractClass
    column integer_value : Int32

    def print_value : String
      "#{integer_value}"
    end
  end

  class ConcreteClass2 < AbstractClass
    column string_value : String

    def print_value : String
      string_value
    end
  end

  class PolymorphicMigration4321
    include Clear::Migration

    def change(dir)
      create_table "polymorphs" do |t|
        t.text "type", index: true, null: false
        t.text "string_value"
        t.integer "integer_value"
        t.integer "common_value"
      end
    end
  end

  def self.reinit
    reinit_migration_manager
    PolymorphicMigration4321.new.apply(Clear::Migration::Direction::UP)
  end

  describe "Clear::Model::IsPolymorphic" do
    it "has a field telling you if the model class is polymorphic" do
      AbstractClass.polymorphic?.should eq true
      ConcreteClass1.polymorphic?.should eq true
      ConcreteClass2.polymorphic?.should eq true
      OtherModel.polymorphic?.should eq false
    end

    it "properly save and load a concrete model" do
      temporary do
        reinit

        c = ConcreteClass1.new
        c.integer_value = 1
        c.save!

        AbstractClass.query.count.should eq 1
        AbstractClass.query.first!.is_a?(ConcreteClass1).should eq true
        AbstractClass.query.first!.print_value.should eq "1"
      end
    end

    it "filters the subclass using the type column" do
      temporary do
        reinit

        5.times { ConcreteClass1.create({integer_value: 1, common_value: 1}) }
        10.times { ConcreteClass2.create({string_value: "Yey", common_value: 1}) }

        ConcreteClass1.query.count.should eq 5

        ConcreteClass2.query.count.should eq 10
        AbstractClass.query.count.should eq 15
      end
    end

    it "loads the model correctly" do
      temporary do
        reinit

        5.times { ConcreteClass1.create({integer_value: 1}) }
        10.times { ConcreteClass2.create({string_value: "Yey"}) }

        c1, c2 = 0, 0
        AbstractClass.query.each do |mdl|
          if mdl.is_a? ConcreteClass1
            c1 += 1
          elsif mdl.is_a? ConcreteClass2
            c2 += 1
          end
        end

        c1.should eq 5
        c2.should eq 10
      end
    end
  end
end
