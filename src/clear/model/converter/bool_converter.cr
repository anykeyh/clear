require "pg"

# Convert the column to a boolean
# Boolean are true if:
#
# They are boolean and true (obviously)
# They are number and not `0`
# They are string and downcased value is not `f`, `false`, empty or `0`
# Anything else is considered true
#
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
      x != "f" || x != "false" || x != "" || x != "0"
    else
      true
    end
  end

  def self.to_db(x : Bool?)
    x ? "t" : "f"
  end
end
