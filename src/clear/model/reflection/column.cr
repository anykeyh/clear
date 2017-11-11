# Reflection of the columns using information_schema in postgreSQL.
class Clear::Reflection::Column
  include Clear::Model

  self.table = "information_schema.columns"

  field table_catalog : String
  field table_schema : String
  field table_name : String

  def table : Clear::Reflection::Table
    Column.query.where { var("table_name") == self.table_name }.first
  end
end
