require "../spec_helper"

module FullTextSearchableSpec
  class Series
    include Clear::Model

    with_serial_pkey

    full_text_searchable "tsv"

    self.table = "series"

    column title : String
    column description : String
  end

  class CreateSeriesMigration5312354
    include Clear::Migration

    def change(dir)
      create_table "series" do |t|
        t.string "title"
        t.string "description"
        t.full_text_searchable on: [{"title", 'A'}, {"description", 'C'}], column_name: "tsv"
      end
    end
  end

  def self.reinit
    reinit_migration_manager
    CreateSeriesMigration5312354.new.apply(Clear::Migration::Direction::UP)
  end

  describe "test tsv searchable" do
    it "Can translate client query to ts_query" do
      Clear::Model::FullTextSearchable.text_to_search("rick & morty").should eq("'rick' | '&' | 'morty'")
      Clear::Model::FullTextSearchable.text_to_search("rick+morty").should eq("'rick morty'")
      Clear::Model::FullTextSearchable.text_to_search("\"rick morty\"").should eq("'rick morty'")
      Clear::Model::FullTextSearchable.text_to_search("'rick morty'").should eq("'rick morty'")
      Clear::Model::FullTextSearchable.text_to_search("rick morty").should eq("'rick' | 'morty'")
      Clear::Model::FullTextSearchable.text_to_search("rick -morty").should eq("'rick' & !'morty'")
      Clear::Model::FullTextSearchable.text_to_search("rick -'rick hunter'").should eq("'rick' & !'rick hunter' ")
      Clear::Model::FullTextSearchable.text_to_search("l'esplanade").should eq("'l' | 'esplanade'")
    end

    it "Can search through TS vector" do
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
        Series.query.search("break & !prison").count.should eq 2
        Series.query.search("break | throne").count.should eq 4
      end
    end
  end
end
