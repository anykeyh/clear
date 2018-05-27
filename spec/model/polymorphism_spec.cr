require "../spec_helper"

module ModelSpec
  abstract class AbstractClass
    include Clear::Model

    self.table = "polymorphs"

    polymorphic   ::ModelSpec::ConcreteClass1,
                  ::ModelSpec::ConcreteClass2,
                  through: "type"

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
      end
    end
  end

  describe "Clear::Model::IsPolymorphic" do
    it "has a field telling you if the model class is polymorphic" do
      ModelSpec::AbstractClass.polymorphic?.should eq true
      ModelSpec::ConcreteClass1.polymorphic?.should eq true
      ModelSpec::ConcreteClass2.polymorphic?.should eq true
      ModelSpec::OtherModel.polymorphic?.should eq false
    end

    it "properly save and load a concrete model" do
      temporary do
        reinit_migration_manager
        PolymorphicMigration4321.new.apply(Clear::Migration::Direction::UP)

        c = ConcreteClass1.new
        c.integer_value = 1
        c.save!

        AbstractClass.query.count.should eq 1
        AbstractClass.query.first!.is_a?(ConcreteClass1).should eq true
        AbstractClass.query.first!.print_value.should eq "1"
      end
    end

  end

end

