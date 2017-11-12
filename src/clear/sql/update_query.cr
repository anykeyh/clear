require "db"
require "pg"
require "./sql"

# WIP
class Clear::SQL::UpdateQuery
  alias Updatable = Clear::SQL::Any | BigInt | BigFloat | Time
  alias UpdateInstruction = Hash(String, Updatable) | String

  @values : Array(UpdateInstruction) = [] of UpdateInstruction
  @table : String

  include Query::Where
  include Query::Execute

  def initialize(table, @wheres = [] of Clear::Expression::Node)
    @table = table.to_s
  end

  def set(row : NamedTuple)
    set(row.to_h)
    self
  end

  def set(row : String)
    @values << row
    self
  end

  def set(row : Hash(String, Updatable))
    @values << Hash(String, Updatable).new.merge(row) # Merge to avoid a bug in crystal
    self
  end

  protected def print_value(row : Hash(String, Updatable)) : String
    row.map { |k, v| [k.to_s, Clear::Expression[v]].join(" = ") }.join(", ")
  end

  protected def print_values : String
    @values.map do |x|
      case x
      when String
        x
      when Hash(String, Updatable)
        print_value(x)
      end
    end.join(", ")
  end

  def to_sql
    raise Clear::SQL::QueryBuildingError.new("Update Query must have a table clause.") if @table.nil?
    ["UPDATE #{@table} SET", print_values, print_wheres].compact.join(" ")
  end
end
