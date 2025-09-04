require "../spec_helper"
require "../data/example_models"

module ColumnSpec
  describe "Clear::Model" do
    context "columns" do
      it "handles persistance flag" do
        temporary do
          reinit_example_models

          u = User.new({id: 1, first_name: "Henry"})
          u.persisted?.should be_false
          u.save!

          u.persisted?.should be_true
          u = User.new({id: 2, first_name: "John"}, persisted: true)
          u.persisted?.should be_true
          u.first_name = "Rick"
          u.save! # Will try to update model with id=2.

          User.query.where(id: 2).empty?.should be_true
        end
      end

      it "handles dirty flag" do
        temporary do
          reinit_example_models

          u = User.create!(id: 1, first_name: "Henry")

          u.first_name = "Rick"
          u.changed?.should be_true
          u.update_h.should eq({"first_name" => "Rick"})

          u.clear_change_flags
          u.changed?.should be_false

          u.first_name_column.revert
          u.first_name.should eq("Rick")
        end
      end

      it "can't read non-initialized column" do
        temporary do
          reinit_example_models

          u = User.new({id: 1, first_name: "Henry"})

          u.last_name_column.defined?.should be_false
          expect_raises(Exception) { u.last_name }
        end
      end

      it "can revert a column to previous state" do
        temporary do
          reinit_example_models
          u = User.new({id: 1, first_name: "Henry"})

          u.first_name = "John"
          u.first_name_column.revert
          u.first_name.should eq("Henry")
          u.first_name = "John"
          u.save!

          u.first_name = "Hiro"
          u.first_name = "Jean"
          u.first_name_column.revert
          u.first_name.should eq("John") # We do not revert to Hiro since it has never been persisted

          u.first_name = "Hiro"
          u.save!
          u.first_name_column.revert
          u.first_name.should eq("Hiro")
        end
      end

      it "can setup a default value to column if not defined" do
        temporary do
          reinit_example_models
          u = User.new({id: 1, first_name: "John"})
          u.last_name_column.value("Doe").should eq("Doe")
          u.last_name = "Wick"
          u.last_name_column.value("Doe").should eq("Wick")
        end
      end
    end
  end
end
