require "../spec_helper"

module ReflectionSpec
  describe "Clear::Reflection::Table" do
    context "querying" do
      it "can list the tables" do
        temporary do
          first_table = Clear::Reflection::Table.query.first!
          first_column = first_table.columns.first!
        end
      end

      it "will fail to update the view" do
        temporary do
          first_table = Clear::Reflection::Table.query.first!

          expect_raises Clear::Model::ReadOnlyModelError do
            first_table.save
          end
        end
      end
    end
  end

end