require "../spec_helper"

module ParserSpec
  extend self

  describe "Clear::SQL" do
    describe "Parser" do

      it "parse correctly" do
        Clear::SQL::Parser.parse(<<-SQL
          SELECT * FROM "users" where (id > 100 and active is null);
          SELECT 'string' as text;
          -- This is a comment
        SQL
        ) do |token|
          # TODO: Finish the parser
        end
      end
    end
  end
end