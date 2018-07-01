module Clear::Model::FullTextSearchable
  # Set this model as searchable using tsvector
  macro full_text_searchable(through = "full_text_vector", catalog = "pg_catalog.english")
    # TODO: Use converter and tsv structure
    column( {{through.id}} : String, presence: false )

    scope "search" do |str|
      where{ op({{through.id}}, to_tsquery({{catalog}}, str), "@@") }
    end
  end

  # Parse client side text and generate string ready to be ingested by PG's `to_tsquery`.
  #
  # Author note: pg `to_tsquery` is awesome but can easily fail to parse.
  #   `search` method use then a wrapper text_to_search used to ensure than
  #   request is understood and produce ALWAYS legal string for `to_tsquery`
  def self.text_to_search(text)
    text
  end
end
