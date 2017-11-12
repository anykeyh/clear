require "pg"

class Clear::Model::Converter::JSON::AnyConverter
  def self.to_column(x : ::Clear::SQL::Any) : ::JSON::Any?
    case x
    when Nil
      nil
    when ::JSON::Any
      x
    else
      ::JSON.parse(x.to_s)
    end
  end

  def self.to_db(x : ::JSON::Any?)
    x.to_json
  end
end
