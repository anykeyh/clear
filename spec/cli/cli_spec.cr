require "../spec_helper"

temporary do
  describe "Generator" do
    it "can generate a new project" do
      begin
        system("mkdir -p generated")
        Clear::CLI::Generate.run_generator("kemal", [""], "generated")
      ensure
        # system("rm -r generated")
      end
    end

    it "can list the generator" do
      Clear::CLI.run("generate", "--list")
    end
  end
end
