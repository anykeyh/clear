require "../spec_helper"

module MultipleConnectionsSpec
  class Post
    include Clear::Model

    self.table = "models_posts_two"

    column id : Int32, primary: true, presence: false
    column title : String
  end

  class PostStat
    include Clear::Model

    self.connection = "secondary"
    self.table = "models_post_stats"

    column id : Int32, primary: true, presence: false
    column post_id : Int32
  end

  class ModelSpecMigration1234
    include Clear::Migration

    def change(dir)
      create_table "models_posts_two" do |t|
        t.column "title", "string", index: true
      end
    end
  end

  def self.reinit
    reinit_migration_manager
    ModelSpecMigration1234.new.apply
  end

  describe "Clear::Model" do
    context "multiple connections" do
      it "know about the different connections on models" do
        Post.connection.should eq "default"
        PostStat.connection.should eq "secondary"
      end

      it "can load data from the default database" do
        temporary do
          reinit
          p = Post.new({title: "some post"})
          p.save
          p.persisted?.should be_true
        end
      end

      it "can insert data into the secondary database" do
        temporary do
          reinit
          p = PostStat.new({post_id: 1})
          p.save
          p.persisted?.should be_true
          p.post_id.should eq(1)
        end
      end

      it "can update data on the secondary database" do
        temporary do
          reinit
          p = PostStat.new({post_id: 1})
          p.save

          p = PostStat.query.first.not_nil!
          p.post_id = 2
          p.save

          p = PostStat.query.first.not_nil!
          p.post_id.should eq(2)
        end
      end

      it "can update data on the secondary database" do
        temporary do
          reinit
          p = PostStat.new({post_id: 1})
          p.save
          p.delete.should be_true
        end
      end
    end
  end
end
