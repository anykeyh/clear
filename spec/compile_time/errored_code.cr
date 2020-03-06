require "spec"

module CompileTimeSpec
  struct CrystalCall
    property stdout = IO::Memory.new
    property stderr = IO::Memory.new
    property status

    def initialize(script)
      @status = Process.run("crystal",  ["spec/data/compile_time/#{script}.cr", "--error-trace"],
        output: stdout, error: stderr)
    end

    def stderr_contains?(regexp)
      !!(stderr.to_s =~ regexp)
    end

    def debug
      puts stdout
      puts stderr
    end
  end

  def self.run(script)
    CrystalCall.new(script)
  end

  describe "Error case at compile time" do
    it "should give proper error message when through relation is not found" do
      res = run("has_wrong_through_value")
      res.debug
      res.status.success?.should be_false

      res.stderr_contains?(/Cannot find the relation `model_in_betweens`/).should be_true
    end

    it "should give proper error message when converter is not found" do
      res = run("missing_converter")
      res.status.success?.should be_false

      res.stderr_contains?(/No converter found for `MyCustomRecord`/).should be_true
    end

  end
end