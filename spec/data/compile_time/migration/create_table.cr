require "../../../../src/clear"
require "spec"

class CreateTableMigration
  include Clear::Migration

  def change(dir)
    # 1) create table with some fields
    create_table(:table1) do |t|

    end

  end

end

module CreateTableMigrationSpec
  it "create the table" do
  end

  it "remove the table" do
  end
end