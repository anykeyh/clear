require "../spec_helper"

module NestedQuerySpec
  class NestedQuerySpecMigration9991
    include Clear::Migration

    def change(dir)
      create_table "tags" do |t|
        t.column "taggable_id", "bigint", index: true
        t.column "name", "string"
      end

      create_table "videos" do |t|
        t.column "name", "string"
      end

      create_table "releases" do |t|
        t.column "video_id", "bigint", index: true
        t.column "name", "string"
      end

      <<-SQL
        INSERT INTO videos VALUES   (1,    'Video Title');
        INSERT INTO releases VALUES (1, 1, 'Video Release');
        INSERT INTO tags VALUES     (1, 1, 'foo');
        INSERT INTO tags VALUES     (2, 1, 'bar');
      SQL
      .split(";").each do |qry|
        execute(qry)
      end

    end
  end

  class Tag
    include Clear::Model

    self.table = "tags"

    primary_key

    column name : String
    column taggable_id : Int64

    belongs_to video : Video, foreign_key: :taggable_id
  end

  class Video
    include Clear::Model

    self.table = "videos"

    primary_key

    column name : String

    has_many tags : Tag, foreign_key: "taggable_id"
  end

  class Release
    include Clear::Model

    self.table = "releases"

    primary_key

    column id : Int64, primary: true
    column video_id : Int64
    column name : String

    belongs_to video : Video, foreign_key: :video_id
  end

  def self.reinit
    reinit_migration_manager
    NestedQuerySpecMigration9991.new.apply(Clear::Migration::Direction::UP)
  end


  it "nests the query" do
    temporary do
      reinit

      Release.query
             .with_video(&.with_tags).to_a
    end
  end
end