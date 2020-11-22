require "../../spec_helper"
require "json"

module BoolConverterSpec
  describe "Clear::Model::Converter::BoolConverter" do
    it "converts from boolean" do
      converter = Clear::Model::Converter::BoolConverter
      converter.to_column(1).should eq(true)
      converter.to_column(-1).should eq(true)
      converter.to_column(0).should eq(false)
      converter.to_column(0.0).should eq(false)
      converter.to_column(2).should eq(true)
      converter.to_column(1.0).should eq(true)

      converter.to_column(true).should eq(true)
      converter.to_column(false).should eq(false)

      converter.to_column("f").should eq(false)
      converter.to_column("t").should eq(true)
      converter.to_column("false").should eq(false)
      converter.to_column("true").should eq(true)

      converter.to_column(nil).should eq(nil)

      # Anything else than string or number is true
      converter.to_column([] of String).should eq(true)
    end

    it "transform boolean to 't' and 'f'" do
      converter = Clear::Model::Converter::BoolConverter
      converter.to_db(true).should eq("t")
      converter.to_db(false).should eq("f")
      # To ensure we can use the converter with Bool? type.
      converter.to_db(nil).should eq(nil)
    end
  end
end
