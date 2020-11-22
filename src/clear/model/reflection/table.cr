# Reflection of the tables using information_schema in postgreSQL.
# TODO: Usage of view instead of model
class Clear::Reflection::Table
  include Clear::Model

  primary_key "table_name", :text

  self.table = "tables"
  self.schema = "information_schema"

  self.read_only = true

  column table_catalog : String
  column table_schema : String
  column table_name : String, primary: true
  column table_type : String

  scope(:public) { where { table_schema == "public" } }

  scope(:tables_only) { where { table_type == "BASE TABLE" } }
  scope(:views_only) { where { table_type == "VIEW" } }

  has_many columns : Clear::Reflection::Column, foreign_key: "table_name"

  # List all the indexes related to the current table.
  # return an hash where the key is the name of the column
  # and the value is an array containing all the indexes related to this specific
  # field.
  def indexes : Hash(String, Array(String))
    # :nodoc:
    #
    # FROM:
    # https://stackoverflow.com/questions/2204058/list-columns-with-indexes-in-postgresql
    #
    # ```sql
    # select
    #     t.relname as table_name,
    #     i.relname as index_name,
    #     a.attname as column_name
    # from
    #     pg_class t,
    #     pg_class i,
    #     pg_index ix,
    #     pg_attribute a
    # where
    #     t.oid = ix.indrelid
    #     and i.oid = ix.indexrelid
    #     and a.attrelid = t.oid
    #     and a.attnum = ANY(ix.indkey)
    #     and t.relkind = 'r'
    # order by
    #     t.relname,
    #     i.relname;
    # ```
    o = {} of String => Array(String)

    SQL.select({
      index_name:  "i.relname",
      column_name: "a.attname",
    })
      .from({t: "pg_class", i: "pg_class", ix: "pg_index", a: "pg_attribute"})
      .where {
        (t.oid == ix.indrelid) &
          (i.oid == ix.indexrelid) &
          (a.attrelid == t.oid) &
          (a.attnum == raw("ANY(ix.indkey)")) &
          (t.relkind == "r") &
          (t.relname == self.table_name)
      }
      .order_by("t.relname").order_by("i.relname")
      .fetch do |h|
        col = h["column_name"].to_s
        v = h["index_name"].to_s

        arr = o[col]? ? o[col] : (o[col] = [] of String)

        arr << v
      end

    o
  end
end
