require "../spec_helper"

module SeedSpec
  class SeedModel
    include Clear::Model

    self.table = "seed_models"

    primary_key

    column value : String
  end

  class SeedModelMigration96842
    include Clear::Migration

    def change(dir)
      create_table "seed_models" do |t|
        t.column "value", "string", index: true, null: false
      end
    end
  end

  def self.reinit
    reinit_migration_manager
    SeedModelMigration96842.new.apply
  end

  Clear.seed do
    SeedModel.create!({value: "val_a"})
  end

  Clear.seed do
    SeedModel.create!({value: "val_b"})
  end

  describe "Clear::Model::HasScope" do
    it "can access to scope with different arguments " do
      temporary do
        reinit

        Clear.apply_seeds

        SeedModel.query.count.should eq 2
        SeedModel.query.last!.value.should eq "val_b"
      end
    end
  end
end
