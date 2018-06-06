require "pg"

# Convert the column to a boolean
# If value is not boolean (e.g. string or number), rules of `falsey`
# value is used:
#
# falsey's values are:
# false, null, 0, "0", "" (empty string), "false", "f"
# Anything else is considered true
class Clear::Model::Converter::BoolConverter
  def self.to_column(x : ::Clear::SQL::Any) : Bool?
    case x
    when Nil
      nil
    when Bool
      x
    when Number
      x != 0
    when String
      x = x.downcase
      x != "f" && x != "false" && x != "" && x != "0"
    else
      true
    end
  end

  def self.to_db(x : Bool?)
    x ? "t" : "f"
  end
end
