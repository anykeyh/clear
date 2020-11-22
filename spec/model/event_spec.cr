require "../spec_helper"

module EventSpec
  ACCUMULATOR = [] of String

  abstract class ModelA
    include Clear::Model

    polymorphic through: "type"

    before(:validate) { ACCUMULATOR << "1" }
    before(:validate) { ACCUMULATOR << "2" }
    before(:validate) { ACCUMULATOR << "3" }

    after(:validate) { ACCUMULATOR << "6" }
    after(:validate) { ACCUMULATOR << "7" }
    after(:validate) { ACCUMULATOR << "8" }
  end

  class ModelB < ModelA
    before(:validate) { ACCUMULATOR << "A" }

    after(:validate, :x)

    def x
      ACCUMULATOR << "Z"
    end
  end

  describe "Clear::Model" do
    context "EventManager" do
      it "call the events in the good direction" do
        ModelB.new.valid?
        ACCUMULATOR.join("").should eq "123AZ876"
      end
    end
  end
end
