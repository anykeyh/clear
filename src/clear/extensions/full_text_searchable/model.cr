require "./tsvector"

module Clear::Model::FullTextSearchable
  # Set this model as searchable using tsvector
  macro full_text_searchable(through = "full_text_vector", catalog = "pg_catalog.english", scope_name = "search")
    # TODO: Use converter and tsv structure
    column( {{through.id}} : Clear::TSVector, presence: false, converter: Clear::TSVector::Converter )

    scope "#{scope_name.id}" do |str|
      where{ op({{through.id}}, to_tsquery({{catalog}},
        Clear::Model::FullTextSearchable.to_tsq(str)), "@@") }
    end
  end

  # :nodoc:
  # Split a chain written by a user
  # A problem to solve is the `'` character
  def self.split_to_exp(text)
    in_quote = false
    quote_start = nil
    ignore_next_quote = false
    exp = [] of String
    text.chars.each_with_index do |c, idx|
      case c
      when /[A-Z0-9]/i
        # if it's a alphanumerical character
        ignore_next_quote = true
        ignore_next_quote
      when '\'', '"'
        if (in_quote && quote_start == c)
        end

        in_quote = true
        quote_start = c
      end
    end
  end

  # Parse client side text and generate string ready to be ingested by PG's `to_tsquery`.
  #
  # Author note: pg `to_tsquery` is awesome but can easily fail to parse.
  #   `search` method use then a wrapper text_to_search used to ensure than
  #   request is understood and produce ALWAYS legal string for `to_tsquery`
  # This is a good helper then to use with the input of your end-users !
  def self.to_tsq(text)
    return text
    current_str = ""
    in_quote = false
    text.chars.each_with_index do |c, idx|
      case c
      when '\''
        in_quote = !in_quote
        if (!in_quote)
          current_str
        end
      when '-'
      else
      end
    end
  end
end
