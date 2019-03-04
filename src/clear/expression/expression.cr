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

  # Allow any type to be used into the expression engine
  #   by including the module Clear::Expression::Literal
  #   and defining the method `to_sql`.
  module Literal
    abstract def to_sql
    abstract def to_json(x)
  end

  # Wrap an unsafe string. Useful to cancel-out the
  # safe_literal function used internally.
  # Obviously, this can lead to SQL injection, so beware!
  class UnsafeSql
    include Literal

    @value : String

    def initialize(@value)
    end

    def to_s
      @value
    end

    def to_sql
      @value
    end

    def to_json(b = nil)
      @value
    end
  end

  alias AvailableLiteral = Int8 | Int16 | Int32 | Int64 | Float32 | Float64 |
                           UInt8 | UInt16 | UInt32 | UInt64 |
                           Literal | String | Symbol | Time | Bool | Nil

  # A fast way to call `self.safe_literal`
  # See `safe_literal(x : _)`
  def self.[](arg)
    safe_literal(arg)
  end

  # :nodoc:
  def self.safe_literal(x : Number) : String
    x.to_s
  end

  # :nodoc:
  def self.safe_literal(x : Nil) : String
    "NULL"
  end

  # :nodoc:
  def self.safe_literal(x : String) : String
    {"'", x.gsub('\'', "''"), "'"}.join
  end

  # :nodoc:
  def self.safe_literal(x : ::Clear::SQL::SelectBuilder)
    {"(", x.to_sql, ")"}
  end

  # :nodoc:
  def self.safe_literal(x : ::Clear::Expression::Node)
    x.resolve
  end

  # Transform multiple objects into a string which is SQL-Injection safe.
  def self.safe_literal(x : Enumerable(AvailableLiteral)) : Enumerable(String)
    x.map { |item| self.safe_literal(item) }
  end

  # Return unsafe string injected to the query.
  #   can be used for example in `insert` query building
  def self.unsafe(x)
    Clear::Expression::UnsafeSql.new(x)
  end

  # Safe literal of a time return a string representation of time in the format understood by postgresql.
  #
  # If the optional parameter `date` is passed, the time is truncated and only the date is passed:
  #
  # ## Example
  # ```
  # Clear::Expression[Time.now]             # < "2017-04-03 23:04:43.234 +08:00"
  # Clear::Expression[Time.now, date: true] # < "2017-04-03"
  # ```
  def self.safe_literal(x : Time, date : Bool = false) : String
    {"'", x.to_s(date ? DATABASE_DATE_FORMAT : DATABASE_DATE_TIME_FORMAT), "'"}.join
  end

  # :nodoc:
  def self.safe_literal(x : Bool) : String
    (x ? "TRUE" : "FALSE")
  end

  # :nodoc:
  def self.safe_literal(x : Node) : String
    x.resolve
  end

  # :nodoc:
  def self.safe_literal(x : UnsafeSql) : String
    x.to_s
  end

  # Sanitize an object and return a `String` representation of itself which is proofed against SQL injections.
  def self.safe_literal(x : _) : String
    self.safe_literal(x.to_s)
  end

  # This method will raise error on compilation if discovered in the code.
  # This allow to avoid issues like this one at compile type:
  #
  # ```crystal
  # id = 1
  # # ... and later
  # User.query.where { id == 2 }
  # ```
  #
  # In this case, the local var id will be evaluated in the expression engine.
  # leading to buggy code.
  #
  # Having this method prevent the code to compile.
  #
  # To be able to pass a literal or values other than node, please use `raw`
  # method.
  #
  def self.ensure_node!(any)
    {% raise \
         "The expression engine discovered a runtime-evaluable condition.\n" +
         "It happens when a test is done with values on both sides.\n" +
         "Maybe a local variable is breaking the expression engine like here:\n" +
         "id = 1\n" +
         "Users.where{ id == nil }\n\n" +
         "In this case, please use `raw(\"id IS NULL\")` to allow the expression." %}
  end

  # :nodoc:
  def self.ensure_node!(node : Node) : Node
    node
  end

  # Return a node of the expression engine
  # This node can then be combined with others node
  # in case of chain request creation `where{...}.where{...}`
  # through the chaining engine
  def self.where(&block) : Node
    expression_engine = self.new

    ensure_node!(with expression_engine yield)
  end

  # `NOT` operator
  #
  # Return an logically reversed version of the contained `Node`
  #
  # ## Example
  #
  # ```
  # Clear::Expression.where { not(a == b) }.resolve # >> "WHERE NOT( a = b )
  # ```
  def not(x : Node)
    Node::Not.new(x)
  end

  # In case the name of the variable is a reserved word (e.g. `not`, `var`, `raw` )
  # or in case of a complex piece of computation impossible to express with the expression engine
  # (e.g. usage of functions) you can use then raw to pass the String.
  #
  # BE AWARE than the String is pasted AS-IS and can lead to SQL injection if not used properly.
  #
  # ```
  # having { raw("COUNT(*)") > 5 } # SELECT ... FROM ... HAVING COUNT(*) > 5
  # where { raw("func(?, ?) = ?", a, b, c) } # SELECT ... FROM ... WHERE function(a, b) = c
  # ```
  #
  #
  def raw(x : String, *args)
    idx = -1

    clause = x.gsub("?") do |_|
      begin
        Clear::Expression[args[idx += 1]]
      rescue e : IndexError
        raise Clear::ErrorMessages.query_building_error(e.message)
      end
    end

    Node::Raw.new(clause)
  end

  # Use var to create expression of variable. Variables are columns with or without the namespace and tablename:
  #
  # It escapes each part of the expression with double-quote as requested by PostgreSQL.
  # This is useful to escape SQL keywords or `.` and `"` character in the name of a column.
  #
  # ```crystal
  #   var("template1", "users", "name") # "template1"."users"."name"
  #   var("template1", "users.table2", "name") # "template1"."users.table2"."name"
  #   var("order") # "order"
  # ```
  #
  def var(*parts)
    _var(parts)
  end

  # :nodoc:
  private def _var(parts : Tuple, pos = parts.size - 1)
    if pos == 0
      Node::Variable.new(parts[pos].to_s)
    else
      Node::Variable.new(parts[pos].to_s, _var(parts, pos - 1))
    end
  end

  # Because many postgresql operators are not transcriptable in Crystal lang,
  # this helpers helps to write the expressions:
  #
  # ```crystal
  # where { op(jsonb_field, "something", "?") } #<< Return "jsonb_field ? 'something'"
  # ```
  #
  def op(a : (Node | AvailableLiteral), b : (Node | AvailableLiteral), op : String)
    a = Node::Literal.new(a) if a.is_a?(AvailableLiteral)
    b = Node::Literal.new(b) if b.is_a?(AvailableLiteral)

    Node::DoubleOperator.new(a, b, op)
  end

  # :nodoc:
  # Used internally by the expression engine.
  macro method_missing(call)
     {% if call.args.size > 0 %}
       args = {{call.args}}.map{ |x| Clear::Expression[x] }
       return Node::Function.new("{{call.name.id}}", args)
     {% else %}
       return Node::Variable.new({{call.name.id.stringify}})
     {% end %}
  end
end
