# Reflection of the columns using information_schema in postgreSQL.
# TODO: Usage of view instead of model
class Clear::Reflection::Column
  include Clear::Model

  self.table = "information_schema.columns"

  column table_catalog : String
  column table_schema : String
  column table_name : String
  column column_name : String

  def table : Clear::Reflection::Table
    Column.query.where { var("table_name") == self.table_name }.first
  end
end
