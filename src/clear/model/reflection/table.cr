# Reflection of the tables using information_schema in postgreSQL.
class Clear::Reflection::Table
  include Clear::Model

  self.table = "information_schema.tables"

  field table_catalog : String
  field table_schema : String
  field table_name : String

  scope(:public) { where { table_schema == "public" } }

  has columns : Array(Column), foreign_key: "table_name", primary_key: "table_name"
end
