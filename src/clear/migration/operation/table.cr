module Clear::Migration
  # Helper to create or alter table.
  class Table < Operation
    record ColumnOperation, column : String, type : String,
      null : Bool = false, default : SQL::Any = nil, primary : Bool = false,
      array : Bool = false

    record IndexOperation, fields : Array(String), name : String,
      using : String? = nil, unique : Bool = false

    record FkeyOperation, fields : Array(String), table : String,
      foreign_fields : Array(String), on_delete : String, primary : Bool

    getter name : String
    getter schema : String

    getter? is_create : Bool

    getter column_operations : Array(ColumnOperation) = [] of ColumnOperation
    getter index_operations : Array(IndexOperation) = [] of IndexOperation
    getter fkey_operations : Array(FkeyOperation) = [] of FkeyOperation

    def initialize(@name, @schema, @is_create)
      raise "Not yet implemented" unless is_create?
    end

    # Add the timestamps to the field.
    def timestamps(null = false)
      add_column(:created_at, "timestamp without time zone", null: null, default: "NOW()")
      add_column(:updated_at, "timestamp without time zone", null: null, default: "NOW()")
      add_index(["created_at"])
      add_index(["updated_at"])
    end

    def references(to, name : String? = nil, on_delete = "restrict", type = "bigint",
                   null = false, foreign_key = "id", primary = false)
      name ||= to.singularize.underscore + "_id"

      add_column(name, type, null: null, index: true)

      add_fkey(fields: [name.to_s], table: to.to_s, foreign_fields: [foreign_key.to_s],
        on_delete: on_delete.to_s, primary: primary)
    end

    def add_fkey(fields : Array(String), table : String,
                 foreign_fields : Array(String), on_delete : String, primary : Bool)
      self.fkey_operations << FkeyOperation.new(fields: fields, table: table,
        foreign_fields: foreign_fields, on_delete: on_delete, primary: primary)
    end

    # Add/alter a column for this table.
    def add_column(column, type, default = nil, null = true, primary = false,
                   index = false, unique = false, array = false)
      self.column_operations << ColumnOperation.new(column: column.to_s, type: type.to_s,
        default: default, null: null, primary: primary, array: array)

      if unique
        add_index(fields: [column.to_s], unique: true)
      elsif index
        if index.is_a?(Bool)
          add_index(fields: [column.to_s], unique: false)
        else
          add_index(fields: [column.to_s], unique: false, using: index)
        end
      end
    end

    def full_name
      {Clear::SQL.escape(@schema), Clear::SQL.escape(@name)}.join(".")
    end

    # Add or replace an index for this table.
    # Alias for `add_index`
    def index(field : String | Symbol, name = nil, using = nil, unique = false)
      add_index(fields: [field.to_s], name: name, using: using, unique: unique)
    end

    def index(fields : Array, name = nil, using = nil, unique = false)
      add_index(fields: fields.map(&.to_s), name: name, using: using, unique: unique)
    end

    private def add_index(fields : Array(String), name = nil, using = nil, unique = false)
      name ||= safe_index_name([@name, fields.join("_")].join("_"))

      using = using.to_s unless using.nil?

      self.index_operations << IndexOperation.new(
        fields: fields, name: name, using: using, unique: unique
      )
    end

    #
    # Return a safe index name from the condition string
    private def safe_index_name(str)
      str.underscore.gsub(/[^a-zA-Z0-9_]+/, "_")
    end

    def up : Array(String)
      columns_and_fkeys = print_columns + print_fkeys

      content = "(#{columns_and_fkeys.join(", ")})" unless columns_and_fkeys.empty?

      arr = if is_create?
              [
                ["CREATE TABLE", full_name, content].compact.join(" "),
              ]
            else
              # To implement later
              [] of String
            end
      arr + print_indexes
    end

    def down : Array(String)
      [
        (["DROP TABLE", full_name].join(" ") if is_create?),
      ].compact
    end

    private def print_fkeys
      # FOREIGN KEY (b, c) REFERENCES other_table (c1, c2)
      fkey_operations.map do |x|
        ["FOREIGN KEY",
         "(" + x.fields.join(", ") + ")",
         "REFERENCES",
         x.table,
         "(" + x.foreign_fields.join(", ") + ")",
         "ON DELETE",
         x.on_delete]
          .compact.join(" ")
      end
    end

    private def print_indexes
      index_operations.map do |x|
        [
          "CREATE",
          (x.unique ? "UNIQUE" : nil),
          "INDEX",
          x.name,
          "ON",
          self.name,
          (x.using ? "USING #{x.using}" : nil),
          "(#{x.fields.join(", ")})",
        ].compact.join(" ")
      end
    end

    private def print_columns
      column_operations.map do |x|
        [x.column,
         x.type + (x.array ? "[]" : ""),
         x.null ? nil : "NOT NULL",
         !x.default.nil? ? "DEFAULT #{x.default}" : nil,
         x.primary ? "PRIMARY KEY" : nil]
          .compact.join(" ")
      end
    end

    # DEPRECATED
    # Method missing is used to generate add_column using the method name as
    # column type (ActiveRecord's style)
    macro method_missing(caller)
      {% raise "Migration: usage of Table##{caller.name} is deprecated.\n" +
               "Tip: use instead `self.column(NAME, \"#{caller.name}\", ...)`" %}
    end

    def column(name, type, default = nil, null = true, primary = false,
               index = false, unique = false, array = false)
      type = case type.to_s
             when "string"
               "text"
             when "int32", "integer"
               "integer"
             when "int64", "long"
               "bigint"
             when "bigdecimal", "numeric"
               "numeric"
             when "datetime"
               "timestamp without time zone"
             else
               type.to_s
             end

      self.add_column(name.to_s, type: type, default: default, null: null,
        primary: primary, index: index, unique: unique, array: array)
    end
  end

  class AddTable < Operation
    getter table : String
    getter schema : String

    def initialize(@table, @schema)
    end

    def full_name
      {Clear::SQL.escape(@schema), Clear::SQL.escape(@name)}.join(".")
    end

    def up : Array(String)
      ["CREATE TABLE #{@table}"]
    end

    def down : Array(String)
      ["DROP TABLE #{@table}"]
    end
  end

  class DropTable < Operation
    getter table : String
    getter schema : String

    def initialize(@table, @schema)
    end

    def full_name
      {Clear::SQL.escape(@schema), Clear::SQL.escape(@name)}.join(".")
    end

    def up : Array(String)
      ["DROP TABLE #{@table}"]
    end

    def down : Array(String)
      ["CREATE TABLE #{@table}"]
    end
  end

  module Helper
    #
    # Helper used in migration to create a new table.
    #
    # Usage:
    #
    # ```
    # create_table(:users) do |t|
    #   t.column :first_name, :string
    #   t.column :last_name, :string
    #   t.column :email, :string, unique: true
    #   t.timestamps
    # end
    # ```
    #
    # By default, a column `id` of type `integer` will be created as primary key of the table.
    # This can be prevented using `primary: false`
    #
    # ```
    # create_table(:users, id: false) do |t|
    #   t.column :user_id, :integer, primary: true # Use custom name for the primary key
    #   t.column :first_name, :string
    #   t.column :last_name, :string
    #   t.column :email, :string, unique: true
    #   t.timestamps
    # end
    # ```
    #
    def create_table(name, id : Symbol | Bool = true, schema = "public", &block)
      table = Table.new(name.to_s, schema.to_s, is_create: true)
      self.add_operation(table)

      case id
      when true, :bigserial
        table.column "id", "bigserial", primary: true, null: false
      when :serial
        table.column "id", "serial", primary: true, null: false
      when :uuid
        table.column "id", "uuid", primary: true, null: false
      when false
      else
        raise "Unknown key type while try to create new table: `#{id}`. Candidates are :bigserial, :serial and :uuid" +
              "Please proceed with `id: false` and add the column manually"
      end

      yield(table)
    end
  end
end
