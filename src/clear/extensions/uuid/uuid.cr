struct UUID
  def to_json(json)
    json.string(to_s)
  end
end

# Convert from UUID column to Crystal's UUID
class Clear::Model::Converter::UUIDConverter
  def self.to_column(x) : UUID?
    case x
    when String
      UUID.new(x)
    when Slice(UInt8)
      UUID.new(x)
    when UUID
      x
    when Nil
      nil
    else
      raise Clear::ErrorMessages.converter_error(x.class.name, "UUID")
    end
  end

  def self.to_db(x : UUID?)
    x.to_s
  end
end

Clear::Model::Converter.add_converter("UUID", Clear::Model::Converter::UUIDConverter)

Clear::Model::HasSerialPkey.add_pkey_type "uuid" do
  column __name__ : UUID, primary: true, presence: true

  before(:validate) do |m|
    if !m.persisted? && m.as(self).__name___column.value(nil).nil?
      m.as(self).__name__ = UUID.random
    end
  end
end
