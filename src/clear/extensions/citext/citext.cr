# Represents a case insensitive text, used by Postgres
# Wrap a string and basically change the equality check to make it case insensitive.s
struct Citext
  getter string : String

  forward_missing_to @string

  def initialize(@string)
  end

  def ==(x : String | Citext)
    self.compare(x.to_s, true) == 0
  end

  def !=(x : String | Citext)
    !(self == x)
  end
end
