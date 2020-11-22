require "../spec_helper"
require "../data/example_models"

module CustomSchemaSpec
  describe "Model inside another schema" do
    it "can create a model" do
      temporary do
        reinit_example_models

        model = ModelWithinAnotherSchema.create! title: "Some title" # Ensure create works

        model.class.full_table_name.should eq(
          %("another_schema"."model_within_another_schemas")
        )
        model.persisted?.should eq(true)

        mdl = ModelWithinAnotherSchema.query.where { title == "Some title" }.first!

        mdl.title = "A new title"
        mdl.save! # Ensure update works
        ModelWithinAnotherSchema.query.first!.title.should eq("A new title")

        ModelWithinAnotherSchema.query.delete_all # Ensure delete works
        ModelWithinAnotherSchema.query.count.should eq(0)

        model = ModelWithinAnotherSchema.create! title: "Some title" # Ensure create works
        model.delete                                                 # Ensure delete one works

        ModelWithinAnotherSchema.create! title: "Some title" # Ensure create works
        Clear::SQL.truncate(ModelWithinAnotherSchema)        # ensure truncate works
      end
    end
  end
end
