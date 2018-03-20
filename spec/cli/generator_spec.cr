require "../spec_helper"

temporary do
  describe "Generator" do
    it "can generate a new project" do
      begin
        system("mkdir -p generated")
        Clear::CLI.run_generator("kemal", [""], "generated")
      ensure
        # system("rm -r generated")
      end
    end
  end
end
