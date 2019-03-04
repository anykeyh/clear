require "../spec_helper"

module ReflectionSpec
  describe "Clear::Reflection::Table" do
    context "querying" do
      it "can list the tables" do
        temporary do
          first_table = Clear::Reflection::Table.query.first!
          first_table.columns.first!
        end
      end

      it "will fail to update the view" do
        temporary do
          first_table = Clear::Reflection::Table.query.first!

          expect_raises Clear::Model::ReadOnlyError do
            first_table.save!
          end

          first_table.columns.first!.save.should eq false

          expect_raises Clear::Model::ReadOnlyError do
            first_table.columns.first!.save!
          end
        end
      end
    end
  end
end
