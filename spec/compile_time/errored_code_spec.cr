require "../spec_helper"

module CompileTimeSpec
  describe "Error case at compile time" do
    it "should give proper error message when through relation is not found" do
      res = compile_and_run("has_wrong_through_value")
      res.status.success?.should be_false

      res.stderr_contains?(/Cannot find the relation `model_in_betweens`/).should be_true
    end

    it "should give proper error message when converter is not found" do
      res = compile_and_run("missing_converter")
      res.status.success?.should be_false

      res.stderr_contains?(/No converter found for `MyCustomRecord`/).should be_true
    end

    it "should give proper error message when the key of a model is not found" do
      res = compile_and_run("model_column_does_not_exists")
      res.status.success?.should be_false

      res.stderr_contains?(/Cannot find the column `full_name` of the model `MyModel`/).should be_true
    end
  end
end
