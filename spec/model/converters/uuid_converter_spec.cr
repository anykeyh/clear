module UUIDConverterSpec
  it "converts from uuid" do
    converter = Clear::Model::Converter::UUIDConverter
    some_uuid = UUID.random
    converter.to_db(some_uuid).should eq(some_uuid.to_s)
    converter.to_db(nil).should eq(nil)
  end
end
