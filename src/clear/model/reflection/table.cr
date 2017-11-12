# Reflection of the tables using information_schema in postgreSQL.
# TODO: Usage of view instead of model
class Clear::Reflection::Table
  include Clear::Model

  self.table = "information_schema.tables"

  def self.pkey
    nil
  end

  column table_catalog : String
  column table_schema : String
  column table_name : String

  scope(:public) { where { table_schema == "public" } }

  has columns : Array(Clear::Reflection::Column), foreign_key: "table_name", primary_key: "table_name"

  def list_indexes : Hash(String, Array(String))
    # https://stackoverflow.com/questions/2204058/list-columns-with-indexes-in-postgresql
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
    o = {} of String => Array(String)

    req = SQL.select({name: "i.relname", column_name: "a.attname"})
             .from({t: "pg_class", i: "pg_class", ix: "pg_index", a: "pg_attribute"})
             .where { t.oid == ix.indrelid }
             .where { i.oid == ix.indexrelid }
             .where { a.attrelid == t.oid }
             .where { a.attnum == raw("ANY(ix.indkey)") }
             .where { t.relkind == "r" }
             .where { t.relname == self.table_name }
             .order_by("t.relname", "i.relname")
             .fetch do |h|
      pp h
      col = h["column_name"].to_s
      v = h["name"].to_s

      arr = o[col]? ? o[col] : (o[col] = [] of String)

      arr << v
    end

    return o
  end
end
