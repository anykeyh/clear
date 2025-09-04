require "spec"

require "../spec_helper"

module InsertSpec
  extend self

  def insert_request
    Clear::SQL::InsertQuery.new(:users)
  end

  describe "Clear::SQL" do
    describe "InsertQuery" do
      it "can build an insert" do
        insert_request.values({a: "c", b: 12}).to_sql.should eq(
          "INSERT INTO \"users\" (\"a\", \"b\") VALUES ('c', 12)"
        )
      end

      it "can build an insert from sql" do
        insert_request.values(
          Clear::SQL.select.from(:old_users)
            .where { old_users.id > 100 }
        ).to_sql.should eq(
          "INSERT INTO \"users\" (SELECT * FROM \"old_users\" WHERE (\"old_users\".\"id\" > 100))"
        )
      end

      it "can insert with ON CONFLICT" do
        insert_request.values({a: "c", b: 12}).on_conflict("(a)").do_nothing
          .to_sql.should eq(
          "INSERT INTO \"users\" (\"a\", \"b\") VALUES ('c', 12) ON CONFLICT (a) DO NOTHING"
        )

        req = insert_request.values({a: "c", b: 12}).on_conflict("(b)").do_update { |upd|
          upd.set(a: 1).where { b == 2 }
        }

        req.to_sql.should eq(
          %(INSERT INTO "users" ("a", "b") VALUES ('c', 12) ON CONFLICT (b) DO UPDATE SET "a" = 1 WHERE ("b" = 2))
        )

        req = insert_request.values({a: "c", b: 12}).on_conflict { age < 18 }.do_update { |upd|
          upd.set(a: 1).where { b == 2 }
        }

        req.to_sql.should eq(
          %(INSERT INTO "users" ("a", "b") VALUES ('c', 12) ON CONFLICT WHERE ("age" < 18) DO UPDATE SET "a" = 1 WHERE ("b" = 2))
        )
      end

      it "can build an empty insert?" do
        insert_request.to_sql.should eq(
          "INSERT INTO \"users\" DEFAULT VALUES"
        )
      end

      it "can insert unsafe values" do
        insert_request.values({created_at: Clear::Expression.unsafe("NOW()")})
          .to_sql
          .should eq "INSERT INTO \"users\" (\"created_at\") VALUES (NOW())"
      end
    end
  end
end
