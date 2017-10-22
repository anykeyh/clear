require "pg"

class Clear::Model::Converter::StringConverter
  def self.to_field(x : ::Clear::SQL::Any) : String?
    case x
    when Nil
      nil
    when Slice(UInt8)
      String.new(x)
    else
      x.to_s
    end
  end

  def self.to_db(x : String?)
    x
  end
end
