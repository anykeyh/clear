module TimeConverterSpec
  describe "Clear::Model::Converter::TimeConverter" do
    it "converts nil" do
      converter = Clear::Model::Converter::TimeConverter
      converter.to_column(nil).should eq(nil)
    end

    it "converts a time object" do
      converter = Clear::Model::Converter::TimeConverter
      time_obj = Time.local
      converter.to_column(time_obj).should eq(time_obj)
    end

    it "converts date formated like 2020-02-22 09:11:42.476953" do
      converter = Clear::Model::Converter::TimeConverter
      example_date = "2020-02-22 09:11:42.476953"
      time_obj = Time.parse_local(example_date, "%F %X.%L")
      converter.to_column(example_date).should eq(time_obj)
    end

    it "converts date formated like 2020-02-22T09:11:42.476953Z" do
      converter = Clear::Model::Converter::TimeConverter
      example_date = "2020-02-22T09:11:42.476953Z"
      time_obj = Time.parse(example_date, "%FT%X.%6NZ", Time::Location::UTC)
      converter.to_column(example_date).should eq(time_obj)
    end

    it "converts date formated like 2020-02-22T09:11:42Z" do
      converter = Clear::Model::Converter::TimeConverter
      example_date = "2020-02-22T09:11:42Z"
      time_obj = Time.parse(example_date, "%FT%XZ", Time::Location::UTC)
      converter.to_column(example_date).should eq(time_obj)
    end

    it "converts date formated like 2020-02-24T11:05:28+07:00" do
      converter = Clear::Model::Converter::TimeConverter
      example_date = "2020-02-24T11:05:28+07:00"
      time_obj = Time.parse!(example_date, "%FT%X%z")
      converter.to_column(example_date).should eq(time_obj)
    end

    it "converts date formated like 2020-02-11T17:54:49.000Z" do
      converter = Clear::Model::Converter::TimeConverter
      example_date = "2020-02-11T17:54:49.000Z"
      time_obj = Time.parse(example_date, "%FT%X.%LZ", Time::Location::UTC)
      converter.to_column(example_date).should eq(time_obj)
    end
  end
  describe "Clear::Model::Converter::BigDecimal" do
    converter = Clear::Model::Converter::BigDecimalConverter

    it "converts to column" do
      converter.to_column(BigDecimal.new(42.0123))
        .should eq(BigDecimal.new(BigInt.new(420123), 4))

      converter.to_column(BigDecimal.new("42_42_42_24.0123_456_789"))
        .should eq(BigDecimal.new(BigInt.new(424242240123456789), 10))

      converter.to_column(BigDecimal.new("-0.1029387192083710928371092837019283701982370918237"))
        .should eq(BigDecimal.new(BigInt.new("-1029387192083710928371092837019283701982370918237".to_big_i), 49))
    end

    it "converts to db" do
      converter.to_db(BigDecimal.new(42.0123))
        .should eq(BigDecimal.new(BigInt.new(420123), 4))

      converter.to_db(BigDecimal.new("42_42_42_24.0123_456_789"))
        .should eq(BigDecimal.new(BigInt.new(424242240123456789), 10))

      converter.to_db(BigDecimal.new("-0.1029387192083710928371092837019283701982370918237"))
        .should eq(BigDecimal.new(BigInt.new("-1029387192083710928371092837019283701982370918237".to_big_i), 49))
    end
  end
end
