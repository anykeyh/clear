require "../spec_helper"

module ModelDifferentColumnNameSpec
  class Brand
    include Clear::Model

    primary_key
    column name : String, column_name: "brand_name"
    self.table = "brands"
  end

  class ModelDifferentColumnNameSpecMigration8273
    include Clear::Migration

    def change(dir)
      create_table "brands" do |t|
        t.column "brand_name", "string"

        t.timestamps
      end
    end
  end

  def self.reinit
    reinit_migration_manager
    ModelDifferentColumnNameSpecMigration8273.new.apply(Clear::Migration::Direction::UP)
  end

  describe "Clear::Model" do
    context "Column definition" do
      it "can define properties in the model with a name different of the column name in PG" do
        # Here the column "name" is linked to "brand_name" in postgreSQL
        temporary do
          reinit

          Brand.create! name: "Nike"
          Brand.query.first!.name.should eq "Nike"
          Brand.query.where(brand_name: "Nike").count.should eq 1
        end
      end
    end
  end
end
