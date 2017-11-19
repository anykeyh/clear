require "pg"

class Clear::Model::Converter::UInt64Converter
  def self.to_column(x : ::Clear::SQL::Any) : UInt64?
    case x
    when Nil
      nil
    when Number
      UInt64.new(x)
    else
      UInt64.new(x.to_s)
    end
  end

  def self.to_db(x : UInt64?)
    x
  end
end
