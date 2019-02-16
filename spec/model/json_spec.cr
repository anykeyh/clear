require "../spec_helper"
require "./model_spec"

module ModelSpec

  describe "JSON" do
    it "Can load from JSON::Any" do
      json = JSON.parse(%<{"id": 1, "first_name": "hello", "last_name": "boss"}>)

      u = User.new.set(json)
      u.id.should eq 1
      u.first_name.should eq "hello"
      u.last_name.should eq "boss"

      json2 = JSON.parse(%<{"tags": ["a", "b", "c"], "flags": [1, 2, 3]}>)

      pp json2
      p = Post.new(json2)
      p.tags.should eq ["a", "b", "c"]
      p.flags.should eq [1, 2, 3]

      # Manage hash of JSON::Any::Type, convenient for example with Kemal:
      p = Post.new(json2)
      p.tags.should eq ["a", "b", "c"]
      p.flags.should eq [1, 2, 3]
    end
  end

end