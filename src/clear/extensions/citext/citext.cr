# Represents a case insensitive text, used by Postgres
# Wrap a string and basically change the equality check to make it case insensitive.s
struct Citext
  getter string : String

  forward_missing_to @string

  def initialize(@string : String)
  end

  def ==(other : String | Citext)
    self.compare(other.to_s, true) == 0
  end

  def !=(other : String | Citext)
    !(self == other)
  end
end
