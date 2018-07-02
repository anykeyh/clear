require "./tsvector"

module Clear::Model::FullTextSearchable
  # Set this model as searchable using tsvector
  macro full_text_searchable(through = "full_text_vector", catalog = "pg_catalog.english", scope_name = "search")
    column( {{through.id}} : Clear::TSVector, presence: false, converter: Clear::TSVector::Converter )

    scope "{{scope_name.id}}" do |str|
      where{ op({{through.id}}, to_tsquery({{catalog}},
        Clear::Model::FullTextSearchable.to_tsq(str)), "@@") }
    end
  end

  # :nodoc:
  # Split a chain written by a user
  # A problem to solve is the `'` character
  private def self.split_to_exp(text)
    last_char : Char? = nil
    quote_char : Char? = nil
    modifier : Symbol? = nil

    currtoken = [] of Char
    arr_tokens = [] of {Symbol?, String}

    text.chars.each do |c|
      case c
      when '\''
        if quote_char.nil?
          if last_char.to_s =~ /[a-z0-9]/i # Avoid french word e.g. "l'avion"
            currtoken << c
          else
            quote_char = '\''
          end
        elsif quote_char == '\''
          arr_tokens << {modifier, currtoken.join}
          currtoken.clear
          modifier = nil
          quote_char = nil
        else
          currtoken << c
        end
      when ' '
        if quote_char.nil?
          if currtoken.any?
            arr_tokens << {modifier, currtoken.join}
            currtoken.clear
          end
          modifier = nil
        else
          currtoken << c
        end
      when '"'
        if (quote_char.nil?)
          quote_char = '"'
        elsif quote_char == '"'
          arr_tokens << {modifier, currtoken.join}
          currtoken.clear
          modifier = nil
          quote_char = nil
        else
          currtoken << c
        end
      when '-'
        if currtoken.empty? && quote_char.nil? # When first char of the token == `-`
          modifier = :-
        else
          currtoken << c
        end
      else
        currtoken << c
      end

      last_char = c
    end

    if currtoken.any?
      arr_tokens << {modifier, currtoken.join}
    end

    arr_tokens
  end

  # Parse client side text and generate string ready to be ingested by PG's `to_tsquery`.
  #
  # Author note: pg `to_tsquery` is awesome but can easily fail to parse.
  #   `search` method use then a wrapper text_to_search used to ensure than
  #   request is understood and produce ALWAYS legal string for `to_tsquery`
  # This is a good helper then to use with the input of your end-users !
  #
  # However, this helper can be improved, as it doesn't use all the features
  # of tsvector (parentesis, OR operator etc...)
  def self.to_tsq(text)
    text = text.gsub(/\+/, " ")
    tokens = split_to_exp(text)

    return tokens.map do |(modifier, value)|
      if modifier == :-
        "!" + Clear::Expression[value]
      else
        Clear::Expression[value]
      end
    end.join(" & ")
  end
end
