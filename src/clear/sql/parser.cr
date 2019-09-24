
# :nodoc:
#
# Small & ugly SQL parser used ONLY for colorizing the query.
module Clear::SQL::Parser

  SQL_KEYWORDS = Set(String).new(%w(
    ADD ALL ALTER ANALYSE ANALYZE AND ANY ARRAY AS ASC ASYMMETRIC
    BEGIN BOTH BY CASE CAST CHECK COLLATE COLUMN COMMIT CONSTRAINT COUNT CREATE CROSS
    CURRENT_DATE CURRENT_ROLE CURRENT_TIME CURRENT_TIMESTAMP
    CURRENT_USER CURSOR DECLARE DEFAULT DELETE DEFERRABLE DESC
    DISTINCT DROP DO ELSE END EXCEPT EXISTS FALSE FETCH FULL FOR FOREIGN FROM GRANT
    GROUP HAVING IF IN INDEX INNER INSERT INITIALLY INTERSECT INTO JOIN LAGGING
    LEADING LIMIT LEFT LOCALTIME LOCALTIMESTAMP NATURAL NEW NOT NULL OFF OFFSET
    OLD ON ONLY OR ORDER OUTER PLACING PRIMARY REFERENCES RELEASE RETURNING
    RIGHT ROLLBACK SAVEPOINT SELECT SESSION_USER SET SOME SYMMETRIC
    TABLE THEN TO TRAILING TRIGGER TRUE UNION UNIQUE UPDATE USER USING VALUES
    WHEN WHERE WINDOW
  ))

  enum Modes
    Normal
    Relation
    String
    Comment
  end

  enum TokenType
    Keyword
    Relation
    Number
    String
    Wildcard
    Symbol
    SimpleWord
    Comment
    Space
  end

  record Token, content : String, type : TokenType

  private def self.findtype( x : String )
    return TokenType::Wildcard if x == "*"
    return TokenType::Space if x == " " || x == "\n"
    return TokenType::Keyword if SQL_KEYWORDS.includes?(x.upcase)
    return TokenType::Number if x =~ /[0-9]+(\.[0-9]+)?(e[0-9]+)?/
    return TokenType::SimpleWord if x =~ /^[A-Za-z_]([A-Za-z_0-9]+)?$/
    return TokenType::Symbol
  end

  def self.parse(sql : String)
    mode = Modes::Normal

    io = Char::Reader.new(sql)

    content = IO::Memory.new

    while io.has_next?
      c = io.next_char

      content << c

      case mode
      when Modes::Normal
        case c
        when ' '
          if io.peek_next_char != ' '
            yield Token.new(content.to_s, TokenType::Space )
            content.clear
          end
        when '"', '\''
          keyword = content.to_s[0..-2] #Remove the last ' '

          yield Token.new(keyword, findtype(keyword) ) unless keyword.empty?
          yield Token.new(" ", TokenType::Space ) if c == " "

          content.clear
          content << c

          mode = Modes::Relation if c == '"'
          mode = Modes::String if c == '\''
        when '-'
          if io.peek_next_char == '-'
            keyword = content.to_s[0..-2] #Remove the '-'
            yield Token.new(keyword, findtype(keyword) )

            content.clear
            content << c

            content.clear
            mode = Modes::Comment
          end
        end
      when Modes::Comment
        case c
        when '\n'
          keyword = content.to_s
          yield Token.new(keyword, findtype(keyword) )

          content.clear
          mode = Modes::Normal
        end
      when Modes::Relation
        case c
        when '"'
          if io.peek_next_char != '"'
            mode = Modes::Normal
            yield Token.new(content.to_s, TokenType::Relation)
            content.clear
          else
            content << io.next_char
          end
        end
      when Modes::String
        case c
        when '\''
          if io.peek_next_char != '\''
            # Close the string
            mode = Modes::Normal
            yield Token.new(content.to_s, TokenType::String)
            content.clear
          else
            content << io.next_char
          end
        end
      end

    end

  end

end