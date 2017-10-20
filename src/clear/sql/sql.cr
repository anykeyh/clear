require "../expression/expression"
require "./select_query"
require "./delete_query"
require "./insert_query"

module Clear
  # Helpers to create SQL tree
  module SQL
    class Error < Exception; end

    class QueryBuildingError < Error; end

    extend self

    alias Symbolic = String | Symbol
    alias Selectable = Symbolic | Clear::SQL::SelectQuery

    def sanitize(x : String, delimiter = "''")
      x.gsub("'", delimiter)
    end

    def sel_str(s : Selectable)
      s.is_a?(Symbolic) ? s.to_s : s.to_sql
    end

    def select(*args)
      if args.size > 0
        Clear::SQL::SelectQuery.new.select(*args)
      else
        Clear::SQL::SelectQuery.new
      end
    end
  end
end

require "./fragment/*"
