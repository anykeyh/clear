require "spec"

require "../spec_helper"

module InsertSpec
  extend self

  describe "Clear::SQL" do
    describe "UpdateQuery" do
      it "allows usage of unsafe SQL fragment" do
        Clear::SQL.update(:model)
          .set("array": Clear::SQL.unsafe("array_replace(array, 'a', 'b')")
          ).to_sql.should eq %(UPDATE "model" SET "array" = array_replace(array, 'a', 'b'))
      end
    end
  end
end
