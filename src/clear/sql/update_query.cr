require "db"
require "pg"
require "./sql"

# TODO: Documentation
class Clear::SQL::UpdateQuery
  alias Updatable = Clear::SQL::Any | BigInt | BigFloat | Time
  alias UpdateInstruction = Hash(String, Updatable) | String

  @values : Array(UpdateInstruction) = [] of UpdateInstruction
  @table : Symbolic?

  include Query::CTE
  include Query::Connection
  include Query::Change
  include Query::Where
  include Query::Execute

  def initialize(@table, @wheres = [] of Clear::Expression::Node)
  end

  def set(row : NamedTuple)
    h = {} of String => Updatable
    row.each { |k, v| h[k.to_s] = v }
    set(h)

    change!
  end

  def set(**row)
    set(row)
  end

  def set(row : String)
    @values << row
    change!
  end

  def set(row : Hash(String, Updatable))
    @values << Hash(String, Updatable).new.merge(row) # Merge to avoid a bug in crystal
    change!
  end

  # :nodoc:
  protected def print_value(row : Hash(String, Updatable)) : String
    row.join(", ") { |k, v| [Clear::SQL.escape(k.to_s), Clear::Expression[v]].join(" = ") }
  end

  # :nodoc:
  protected def print_values : String
    @values.join(", ") do |x|
      case x
      when String
        x
      when Hash(String, Updatable)
        print_value(x)
      else
        "NULL"
      end
    end
  end

  def to_sql
    table = @table.is_a?(Symbol) ? SQL.escape(@table.to_s) : @table

    [print_ctes, "UPDATE", table, "SET", print_values, print_wheres].compact.join(" ")
  end
end
