require "pg"

class Clear::Model::Converter::Int32Converter
  def self.to_field(x : ::Clear::SQL::Any) : Int32?
    case x
    when Nil
      nil
    when Number
      Int32.new(x)
    else
      x.to_s.to_i
    end
  end

  def self.to_db(x : Int32?)
    x
  end
end
