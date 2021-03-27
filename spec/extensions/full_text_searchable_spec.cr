require "../spec_helper"

module FullTextSearchableSpec
  class Series
    include Clear::Model

    primary_key

    full_text_searchable "tsv"

    self.table = "series"

    column title : String
    column description : String
  end

  class CreateSeriesMigration5312354
    include Clear::Migration

    def change(dir)
      create_table "series" do |t|
        t.column "title", "string"
        t.column "description", "string"
        t.full_text_searchable on: [{"title", 'A'}, {"description", 'C'}], column_name: "tsv"
      end
    end
  end

  def self.reinit
    reinit_migration_manager
    CreateSeriesMigration5312354.new.apply
  end

  describe "test tsv searchable" do
    it "Can translate client query to ts_query" do
      Clear::Model::FullTextSearchable.to_tsq("rick & morty").should eq("'rick' & '&' & 'morty'")
      Clear::Model::FullTextSearchable.to_tsq("rick+morty").should eq("'rick' & 'morty'")
      Clear::Model::FullTextSearchable.to_tsq("\"rick morty\"").should eq("'rick morty'")
      Clear::Model::FullTextSearchable.to_tsq("'rick morty'").should eq("'rick morty'")
      Clear::Model::FullTextSearchable.to_tsq("rick morty").should eq("'rick' & 'morty'")
      Clear::Model::FullTextSearchable.to_tsq("rick -morty").should eq("'rick' & !'morty'")
      Clear::Model::FullTextSearchable.to_tsq("rick -'rick hunter'").should eq("'rick' & !'rick hunter'")
      Clear::Model::FullTextSearchable.to_tsq("l'esplanade").should eq("'l''esplanade'")
      Clear::Model::FullTextSearchable.to_tsq("'l''usine'").should eq("'l' & 'usine'")
      Clear::Model::FullTextSearchable.to_tsq("'l'usine").should eq("'l' & 'usine'")
    end

    it "Can search through tsvector" do
      temporary do
        reinit

        Series.create!({title: "Breaking bad", description: "Follow a dying badass " +
                                                            "professor diving into cooking some meth."})
        Series.create!({title: "Game of thrones", description: "Winter is coming."})
        Series.create!({title:       "Better call saul",
                        description: "Follow Saul Goodman," +
                                     "the sketchy lawyer from breaking bad"})
        Series.create!({title:       "Prison break",
                        description: "Going in jail and escape with his innocent brother"})

        Series.query.search("breaking").count.should eq 3
        Series.query.search("break -prison").count.should eq 2
        Series.query.search("break throne").count.should eq 0
      end
    end
  end

  it "Can convert tsvector" do
    temporary do
      reinit

      Series.create!({title: "Breaking bad", description: "Follow a dying badass " +
                                                          "professor diving into cooking some meth."})
      Series.create!({title: "Game of thrones", description: "Winter is coming."})
      Series.create!({title:       "Better call saul",
                      description: "Follow Saul Goodman," +
                                   "the sketchy lawyer from breaking bad"})
      Series.create!({title:       "Prison break",
                      description: "Going in jail and escape with his innocent brother"})
      Series.create!({title:       "",
                      description: ""})

      Series.query.each(&.tsv.to_sql)
    end
  end

  describe "Clear::TSVector" do
    it "can be encoded/decoded" do
      data = ("\u0000\u0000\u0000\tbad\u0000\u0000\u0001@\fbetter\u0000\u0000\u0001" +
              "\xC0\u0001break\u0000\u0000\u0001@\vcall\u0000\u0000\u0001\xC0\u0002" +
              "follow\u0000\u0000\u0001@\u0004goodman\u0000\u0000\u0001@\u0006lawyer" +
              "\u0000\u0000\u0001@\tsaul\u0000\u0000\u0002\xC0\u0003@\u0005sketchi" +
              "\u0000\u0000\u0001@\b").bytes
      # Example specs
      tsvec = Clear::TSVector.decode(
        Slice(UInt8).new(data.to_unsafe, data.size)
      )

      tsvec["bad"].positions[0].position.should eq(12)
      tsvec["bad"].positions[0].weight.should eq('A')

      tsvec["follow"].positions[0].position.should eq(4)
      tsvec["follow"].positions[0].weight.should eq('A')

      tsvec["other"]?.should be_nil
      tsvec.to_sql.should eq "'bad':12A 'better':1A 'break':11A 'call':2A " +
                             "'follow':4A 'goodman':6A 'lawyer':9A " +
                             "'saul':3A,5A 'sketchi':8A"
    end
  end
end
