require "./base"

# Convert the column to a boolean
# If value is not boolean (e.g. string or number), rules of `falsey`
# value is used:
#
# falsey's values are:
# `false`, `nil`, `0`, `"0"`, `""` (empty string), `"false"`, `"f"`
#
# Anything else is considered `true`
module Clear::Model::Converter::BoolConverter
  def self.to_column(x) : Bool?
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
    x.nil? ? nil : (
      x ? "t" : "f"
    )
  end
end

Clear::Model::Converter.add_converter("Bool", Clear::Model::Converter::BoolConverter)
