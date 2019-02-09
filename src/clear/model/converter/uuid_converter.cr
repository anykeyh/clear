require "./base"

class Clear::Model::Converter::UUIDConverter
  def self.to_column(x) : UUID?
    case x
    when String
      UUID.new(x)
    when Slice(UInt8)
      UUID.new(x)
    when UUID
      x
    else
      raise "Cannot convert from #{x.class} to UUID"
    end
  end

  def self.to_db(x : UUID?)
    x.to_s
  end
end

Clear::Model::Converter.add_converter("UUID", Clear::Model::Converter::UUIDConverter)
