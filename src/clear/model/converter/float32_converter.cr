require "pg"

class Clear::Model::Converter::Float32Converter
  def self.to_column(x : ::Clear::SQL::Any) : Float32?
    case x
    when Nil
      nil
    when Number
      Float32.new(x)
    else
      x.to_s.to_f
    end
  end

  def self.to_db(x : Float32?)
    x
  end
end
