require "../spec_helper"

module ScopeSpec
  class ScopeModel
    include Clear::Model

    self.table = "scope_models"

    column value : String?

    # Scope with no parameters
    scope("no_value") { where { value == nil } }

    # Scope with one typed parameter
    scope("with_value") { |x| where { value == x } }

    # Scope with splat parameter
    scope("with_values") { |*x| where { value.in?(x) } }
  end

  class ScopeSpecMigration621253
    include Clear::Migration

    def change(dir)
      create_table "scope_models" do |t|
        t.column "value", "integer", index: true, null: true
      end
    end
  end

  def self.reinit
    reinit_migration_manager
    ScopeSpecMigration621253.new.apply
  end

  describe "Clear::Model::HasScope" do
    it "can access to scope with different arguments " do
      temporary do
        reinit

        ScopeModel.create!({value: 1})
        ScopeModel.create!({value: 2})
        ScopeModel.create!({value: 3})

        ScopeModel.create! # Without value

        ScopeModel.no_value.to_sql.should eq("SELECT * FROM \"scope_models\" WHERE (\"value\" IS NULL)")
        ScopeModel.no_value.count.should eq 1
        ScopeModel.with_value(1).to_sql.should eq("SELECT * FROM \"scope_models\" WHERE (\"value\" = 1)")
        ScopeModel.with_value(1).count.should eq 1
        ScopeModel.with_values(1, 2, 3).where { id < 10 }.to_sql.should eq("SELECT * FROM \"scope_models\" WHERE \"value\" IN (1, 2, 3) AND (\"id\" < 10)")
        ScopeModel.with_values(1, 2, 3).count.should eq 3
      end
    end
  end
end
