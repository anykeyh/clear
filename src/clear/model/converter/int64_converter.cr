require "pg"

class Clear::Model::Converter::Int64Converter
  def self.to_column(x : ::Clear::SQL::Any) : Int64?
    case x
    when Nil
      nil
    when Number
      Int64.new(x)
    else
      Int64.new(x.to_s)
    end
  end

  def self.to_db(x : Int64?)
    x
  end
end
