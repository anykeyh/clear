require "../../spec_helper"

# Having specs are essentially the same specs than the WHERE clause.
# This is because the HAVING block behave essentially like the WHERE block (and I'm lazy)
#
# Therefore, the SQL tested in this test battery doesn't make sense.
module HavingSpec
  def self.complex_query
    Clear::SQL.select.from(:users)
      .join(:role_users) { var("role_users", "user_id") == users.id }
      .join(:roles) { var("role_users", "role_id") == var("roles", "id") }
      .having({role: ["admin", "superadmin"]})
      .order_by({priority: :desc, name: :asc})
      .limit(50)
      .offset(50)
  end

  describe Clear::SQL::Query::Having do
    it "accepts simple string as parameter" do
      r = Clear::SQL.select.from(:users).having("a = b")
      r.to_sql.should eq %[SELECT * FROM "users" HAVING a = b]
    end

    it "transforms Nil to NULL" do
      q = Clear::SQL.select.from(:users).having({user_id: nil})
      q.to_sql.should eq %[SELECT * FROM "users" HAVING ("user_id" IS NULL)]
    end

    it "uses IN operator if an array is found" do
      q = Clear::SQL.select.from(:users).having({user_id: [1, 2, 3, 4, "hello"]})
      q.to_sql.should eq %[SELECT * FROM "users" HAVING "user_id" IN (1, 2, 3, 4, 'hello')]
    end

    it "accepts ranges as tuple value and transform them" do
      Clear::SQL.select.from(:users).having({x: 1..4}).to_sql
        .should eq %[SELECT * FROM "users" HAVING ("x" >= 1 AND "x" <= 4)]
      Clear::SQL.select.from(:users).having({x: 1...4}).to_sql
        .should eq %[SELECT * FROM "users" HAVING ("x" >= 1 AND "x" < 4)]
    end

    it "allows prepared query" do
      r = Clear::SQL.select.from(:users).having("a LIKE ?", "hello")
      r.to_sql.should eq "SELECT * FROM \"users\" HAVING a LIKE 'hello'"

      r = Clear::SQL.select.from(:users).having("a LIKE ?", "hello")
      r.to_sql.should eq "SELECT * FROM \"users\" HAVING a LIKE 'hello'"
    end

    it "manages ranges" do
      Clear::SQL.select.from(:users).having({x: 1..4}).to_sql
        .should eq "SELECT * FROM \"users\" HAVING (\"x\" >= 1 AND \"x\" <= 4)"

      Clear::SQL.select.from(:users).having({x: 1...4}).to_sql
        .should eq "SELECT * FROM \"users\" HAVING (\"x\" >= 1 AND \"x\" < 4)"
    end

    it "can prepare query" do
      r = Clear::SQL.select.from(:users).having("a LIKE ?", "hello")
      r.to_sql.should eq "SELECT * FROM \"users\" HAVING a LIKE 'hello'"
    end

    it "raises exception with prepared query" do
      expect_raises Clear::SQL::QueryBuildingError do
        Clear::SQL.select.from(:users).having("a LIKE ? AND b = ?", "hello")
      end
    end

    it "can prepare query with tuple" do
      r = Clear::SQL.select.from(:users).having("a LIKE :hello AND b LIKE :world",
        hello: "h", world: "w")
      r.to_sql.should eq "SELECT * FROM \"users\" HAVING a LIKE 'h' AND b LIKE 'w'"
    end

    it "raises exception if a tuple element is not found" do
      expect_raises Clear::SQL::QueryBuildingError do
        Clear::SQL.select.from(:users).having("a LIKE :halo AND b LIKE :world", hello: "h", world: "w")
      end

      expect_raises Clear::SQL::QueryBuildingError do
        Clear::SQL.select.from(:users).or_having("a LIKE :halo AND b LIKE :world", hello: "h", world: "w")
      end
    end

    it "can prepare group by query" do
      Clear::SQL.select.select("role").from(:users).group_by(:role).order_by(:role).to_sql.should eq \
        "SELECT role FROM \"users\" GROUP BY \"role\" ORDER BY \"role\" ASC"
    end

    it "can use different comparison and arithmetic operators" do
      r = Clear::SQL.select.from(:users).having { users.id > 1 }
      r.to_sql.should eq "SELECT * FROM \"users\" HAVING (\"users\".\"id\" > 1)"
      r = Clear::SQL.select.from(:users).having { users.id < 1 }
      r.to_sql.should eq "SELECT * FROM \"users\" HAVING (\"users\".\"id\" < 1)"
      r = Clear::SQL.select.from(:users).having { users.id >= 1 }
      r.to_sql.should eq "SELECT * FROM \"users\" HAVING (\"users\".\"id\" >= 1)"
      r = Clear::SQL.select.from(:users).having { users.id <= 1 }
      r.to_sql.should eq "SELECT * FROM \"users\" HAVING (\"users\".\"id\" <= 1)"
      r = Clear::SQL.select.from(:users).having { users.id * 2 == 1 }
      r.to_sql.should eq "SELECT * FROM \"users\" HAVING ((\"users\".\"id\" * 2) = 1)"
      r = Clear::SQL.select.from(:users).having { users.id / 2 == 1 }
      r.to_sql.should eq "SELECT * FROM \"users\" HAVING ((\"users\".\"id\" / 2) = 1)"
      r = Clear::SQL.select.from(:users).having { users.id + 2 == 1 }
      r.to_sql.should eq "SELECT * FROM \"users\" HAVING ((\"users\".\"id\" + 2) = 1)"
      r = Clear::SQL.select.from(:users).having { users.id - 2 == 1 }
      r.to_sql.should eq "SELECT * FROM \"users\" HAVING ((\"users\".\"id\" - 2) = 1)"
      r = Clear::SQL.select.from(:users).having { -users.id < -1000 }
      r.to_sql.should eq "SELECT * FROM \"users\" HAVING (-\"users\".\"id\" < -1000)"
    end

    it "can use expression engine equal" do
      r = Clear::SQL.select.from(:users).having { users.id == var("test") }
      r.to_sql.should eq "SELECT * FROM \"users\" HAVING (\"users\".\"id\" = \"test\")"
    end

    it "can use expression engine not equals" do
      r = Clear::SQL.select.from(:users).having { users.id != 1 }
      r.to_sql.should eq "SELECT * FROM \"users\" HAVING (\"users\".\"id\" <> 1)"
    end

    it "can use expression engine not null" do
      r = Clear::SQL.select.from(:users).having { users.id != nil }
      r.to_sql.should eq "SELECT * FROM \"users\" HAVING (\"users\".\"id\" IS NOT NULL)"
    end

    it "can use expression engine null" do
      r = Clear::SQL.select.from(:users).having { users.id == nil }
      r.to_sql.should eq "SELECT * FROM \"users\" HAVING (\"users\".\"id\" IS NULL)"
    end

    describe "HAVING Expression engine Nodes" do
      it "can stack with `AND` operator" do
        now = Time.local
        r = Clear::SQL.select.from(:users).having { users.id == nil }.having {
          var("users", "updated_at") >= now
        }
        r.to_sql.should eq "SELECT * FROM \"users\" HAVING (\"users\".\"id\" IS NULL) " +
                           "AND (\"users\".\"updated_at\" >= #{Clear::Expression[now]})"
      end

      it "can stack with `OR` operator" do
        now = Time.local
        r = Clear::SQL.select.from(:users).having { users.id == nil }.or_having {
          var("users", "updated_at") >= now
        }
        r.to_sql.should eq "SELECT * FROM \"users\" HAVING ((\"users\".\"id\" IS NULL) " +
                           "OR (\"users\".\"updated_at\" >= #{Clear::Expression[now]}))"
      end

      it "AND and OR" do
        r = Clear::SQL.select.from(:users).having {
          ((raw("users.id") > 100) & (raw("users.visible") == true)) |
            (raw("users.role") == "superadmin")
        }

        r.to_sql.should eq "SELECT * FROM \"users\" HAVING (((users.id > 100) " +
                           "AND (users.visible = TRUE)) OR (users.role = 'superadmin'))"
      end

      it "Operators" do
      end

      it "Between" do
        Clear::SQL.select.having { x.between(1, 2) }
          .to_sql.should eq(%[SELECT * HAVING ("x" BETWEEN 1 AND 2)])

        Clear::SQL.select.having { not(x.between(1, 2)) }
          .to_sql.should eq(%[SELECT * HAVING NOT ("x" BETWEEN 1 AND 2)])
      end

      it "Function" do
        Clear::SQL.select.having { ops_transform(x, "string", raw("INTERVAL '2 seconds'")) }
          .to_sql.should eq(%[SELECT * HAVING ops_transform("x", 'string', INTERVAL '2 seconds')])
      end

      it "InArray" do
        Clear::SQL.select.having { x.in?([1, 2, 3, 4]) }
          .to_sql.should eq(%[SELECT * HAVING "x" IN (1, 2, 3, 4)])

        Clear::SQL.select.having { x.in?({1, 2, 3, 4}) }
          .to_sql.should eq(%[SELECT * HAVING "x" IN (1, 2, 3, 4)])
      end

      it "InRange" do
        # Simple number
        Clear::SQL.select.from(:users).having { users.id.in?(1..3) }.to_sql
          .should eq "SELECT * FROM \"users\" HAVING (\"users\".\"id\" >= 1 AND \"users\".\"id\" <= 3)"

        # Date range.
        range = 2.day.ago..1.day.ago

        Clear::SQL.select.from(:users).having { created_at.in?(range) }.to_sql
          .should eq "SELECT * FROM \"users\" HAVING " +
                     "(\"created_at\" >= #{Clear::Expression[range.begin]} AND" +
                     " \"created_at\" <= #{Clear::Expression[range.end]})"

        # Exclusive range
        Clear::SQL.select.from(:users).having { users.id.in?(1...3) }.to_sql
          .should eq "SELECT * FROM \"users\" HAVING (\"users\".\"id\" >= 1" +
                     " AND \"users\".\"id\" < 3)"
      end

      it "InSelect" do
        sub_query = Clear::SQL.select("id").from("users")
        Clear::SQL.select.having { x.in?(sub_query) }
          .to_sql.should eq(%[SELECT * HAVING "x" IN (SELECT id FROM users)])
      end

      it "Minus" do
        Clear::SQL.select.having { -x > 2 }
          .to_sql.should eq(%[SELECT * HAVING (-"x" > 2)])
      end

      it "Not" do
        Clear::SQL.select.having { not(raw("TRUE")) }
          .to_sql.should eq(%[SELECT * HAVING NOT TRUE])

        Clear::SQL.select.having { ~(raw("TRUE")) }
          .to_sql.should eq(%[SELECT * HAVING NOT TRUE])
      end

      it "Null" do
        Clear::SQL.select.having { x == nil }
          .to_sql.should eq(%[SELECT * HAVING ("x" IS NULL)])
        Clear::SQL.select.having { x != nil }
          .to_sql.should eq(%[SELECT * HAVING ("x" IS NOT NULL)])
      end

      it "Raw" do
        Clear::SQL.select.having { raw("Anything") }
          .to_sql.should eq(%[SELECT * HAVING Anything])

        Clear::SQL.select.having { raw("x > ?", 1) }
          .to_sql.should eq(%[SELECT * HAVING x > 1])

        Clear::SQL.select.having { raw("x > :num", num: 2) }
          .to_sql.should eq(%[SELECT * HAVING x > 2])
      end

      it "Variable" do
        Clear::SQL.select.having { var("public", "users", "id") < 1000 }
          .to_sql.should eq(%[SELECT * HAVING ("public"."users"."id" < 1000)])
      end
    end
  end
end
