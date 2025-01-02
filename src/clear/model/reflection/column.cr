require "./table"

# Reflection of the columns using information_schema in postgreSQL.
# TODO: Usage of view instead of model
class Clear::Reflection::Column
  include Clear::Model

  self.schema = "information_schema"
  self.table = "columns"
  self.read_only = true

  column table_catalog : String
  column table_schema : String
  column table_name : String
  column column_name : String, primary: true

  belongs_to table : Clear::Reflection::Table?, foreign_key: "table_name", foreign_key_type: String

  # def table : Clear::Reflection::Table
  #   Column.query.where { var("table_name") == self.table_name }.first
  # end
end
