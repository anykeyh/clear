###
# ## Clear's Expression engine
#
# The goal of this module is to offer the most natural way to write down your
# query in crystal.
#
# If you're familiar with Sequel on Ruby, then here you have !
#
# Instead of writing:
#
# ```
# model_collection.where("created_at BETWEEN ? AND ?", 1.day.ago, DateTime.now)
# ```
#
# You can write:
# ```
# model_collection.where { created_at.between(1.day.ago, DateTime.now) }
# ```
#
# or even:
# ```
# model_collection.where { created_at.in?(1.day.ago..DateTime.now) }
# ```
#
# (Note for the later, it will generate `created_at > 1.day.ago AND created_at < DateTime.now`)
#
# ## Limitations
#
# Due to the use of `missing_method` macro, some case can be confusing.
#
# ### Existing local variable / instance method
#
# ```
# id = 1
# model_collection.where { id > 100 } # Will raise an error, because the expression is resolved by Crystal !
# # Should be:
# id = 1
# model_collection.where { var("id") > 100 } # Will works
# ```
#
# ### Usage of AND / OR
#
# And/Or can be used using the bitwises operators `&` and `|`.
# Due to the impossibility to reuse `||` and `&&`, beware the operator precendance
# rules are changed.
#
# ```crystal
# # v-- This below will not works, as we cannot redefine the `or` operator
# model_collection.where { first_name == "yacine" || last_name == "petitprez" }
# # v-- This will works, but beware of the parenthesis between each terms, as `|` is prioritary on `==`
# model.collection.where { (firt_name == "yacine") | (last_name == "petitprez") }
# # ^-- ... WHERE first_name = 'yacine' OR last_name == ''
# ```
#
class Clear::Expression
  DATABASE_DATE_TIME_FORMAT = "%Y-%m-%d %H:%M:%S.%L %:z"
  DATABASE_DATE_FORMAT      = "%Y-%m-%d"

  # Wrap an unsafe string. Useful to cancel-out the
  # safe_literal function used internally.
  # Obviously, this can lead to SQL injection, so beware!
  class UnsafeSql
    @value : String

    def initialize(@value)
    end

    def to_s
      @value
    end
  end

  alias AvailableLiteral = Int8 | Int16 | Int32 | Int64 | Float32 | Float64 |
                           UInt8 | UInt16 | UInt32 | UInt64 |
                           UnsafeSql | String | Symbol | Time | Bool | Nil

  # fastest way to call self.safe_literal
  # See `safe_literal(x : _)`
  def self.[](*args) : String
    safe_literal(*args)
  end

  def self.safe_literal(x : Number) : String
    x.to_s
  end

  def self.safe_literal(x : Nil) : String
    "NULL"
  end

  def self.safe_literal(x : String) : String
    "'" + x.gsub(/\'/, "''") + "'"
  end

  def self.safe_literal(x : ::Clear::SQL::SelectBuilder)
    "(#{x.to_sql})"
  end

  #
  # Safe literal of a time is the time in the database format
  # @params date
  #   if date is passed, then only the date part of the Time is used:
  # ```
  # Clear::Expression[Time.now]             # < "2017-04-03 23:04:43.234 +08:00"
  # Clear::Expression[Time.now, date: true] # < "2017-04-03"
  # ```
  def self.safe_literal(x : Time, date : Bool = false) : String
    "'" + x.to_s(date ? DATABASE_DATE_FORMAT : DATABASE_DATE_TIME_FORMAT) + "'"
  end

  def self.safe_literal(x : Bool) : String
    (x ? "TRUE" : "FALSE")
  end

  def self.safe_literal(x : Node) : String
    x.resolve
  end

  def self.safe_literal(x : UnsafeSql) : String
    x.to_s
  end

  def self.safe_literal(x : _) : String
    self.safe_literal(x.to_s)
  end

  def self.to_node(node) : Node
    case node
    when Node
      node
    when Bool
      # UPDATE: Having precomputed boolean return is
      # probably a mistake using the Expression engine
      # It is advisable to raise an error in this case,
      # because a developer mistake can create a boolean where he doesn't want to.
      raise ArgumentError.new("The expression engine discovered a runtime-evaluable condition.\n" +
                              "It happens when a test is done with values on both sides.\n" +
                              "Maybe a local variable is breaking the expression engine like here:\n" +
                              "id = 1\n" +
                              "Users.where{ id == nil }\n\n" +
                              "In this case, please use `raw(\"id IS NULL\")` to allow the expression.")
      # node = Node::Variable.new(node ? "TRUE" : "FALSE")
    else
      raise ArgumentError.new("Node is incorrect, it must be an ExpressionNode")
    end
  end

  # Return a node of the expression engine
  # This node can then be combined with others node
  # in case of chain request creation `where{...}.where{...}`
  # through the chaining engine
  def self.where(&block) : Node
    expression_engine = self.new

    to_node(with expression_engine yield)
  end

  # Not operator
  #
  # ```
  # Clear::Expression.where { not(a == b) }.resolve # >> "WHERE NOT( a = b )
  # ```
  def not(x : Node)
    Node::Not.new(x)
  end

  #
  # In case the name of the variable is a reserved word (e.g. not or ... raw :P)
  # or in case of a complex piece impossible to express with the expression engine
  # (mostly usage of functions)
  # you can use then raw
  #
  # ```
  # where { raw("COUNT(*)") > 5 }
  # ```
  #
  # IDEA: raw should accept array splat as second parameters and the "?" keyword
  #
  def raw(x)
    Node::Variable.new(x.to_s)
  end

  # Alias for `raw`
  #
  # See `raw`
  def var(x)
    raw(x)
  end

  macro method_missing(call)
     {% if call.args.size > 0 %}
       args = {{call.args}}.map{|x| Clear::Expression[x] }.join(", ")
       return Node::Variable.new("{{call.name.id}}( #{args} )")
     {% else %}
       return Node::Variable.new({{call.name.id.stringify}})
     {% end %}
  end
end
