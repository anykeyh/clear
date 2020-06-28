require "../spec_helper"

describe "Generator" do
  it "can generate a new project" do
    begin
      system("mkdir -p generated")
      Clear::CLI::Generator.run
    ensure
      system("rm -r generated")
    end
  end
end
