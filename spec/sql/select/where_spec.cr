require "spec"
require "../../spec_helper"

module WhereSpec
  def self.complex_query
    Clear::SQL.select.from(:users)
      .join(:role_users) { var("role_users", "user_id") == users.id }
      .join(:roles) { var("role_users", "role_id") == var("roles", "id") }
      .where({role: ["admin", "superadmin"]})
      .order_by({priority: :desc, name: :asc})
      .limit(50)
      .offset(50)
  end

  describe Clear::SQL::Query::Where do

    it "accepts simple string as parameter" do
      r = Clear::SQL.select.from(:users).where("a = b")
      r.to_sql.should eq %[SELECT * FROM "users" WHERE a = b]
    end

    it "accepts NamedTuple argument" do
      # tuple as argument
      q = Clear::SQL.select.from(:users).where({user_id: 1})
      q.to_sql.should eq %[SELECT * FROM "users" WHERE ("user_id" = 1)]

      # splatted tuple
      q = Clear::SQL.select.from(:users).where(user_id: 2)
      q.to_sql.should eq %[SELECT * FROM "users" WHERE ("user_id" = 2)]
    end

    it "transforms Nil to NULL" do
      q = Clear::SQL.select.from(:users).where({user_id: nil})
      q.to_sql.should eq %[SELECT * FROM "users" WHERE ("user_id" IS NULL)]
    end

    it "uses IN operator if an array is found" do
      q = Clear::SQL.select.from(:users).where({user_id: [1, 2, 3, 4, "hello"]})
      q.to_sql.should eq %[SELECT * FROM "users" WHERE "user_id" IN (1, 2, 3, 4, 'hello')]
    end

    it "accepts ranges as tuple value and transform them" do
      Clear::SQL.select.from(:users).where({x: 1..4}).to_sql
        .should eq %[SELECT * FROM "users" WHERE ("x" >= 1 AND "x" <= 4)]
      Clear::SQL.select.from(:users).where({x: 1...4}).to_sql
        .should eq %[SELECT * FROM "users" WHERE ("x" >= 1 AND "x" < 4)]
    end

    it "allows prepared query" do
      r = Clear::SQL.select.from(:users).where("a LIKE ?", "hello")
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE a LIKE 'hello'"

      r = Clear::SQL.select.from(:users).where("a LIKE ?", "hello")
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE a LIKE 'hello'"
    end


    it "can use or_where" do
      Clear::SQL.select.from(:users).where("a = ?", 1).or_where("b = ?", 2).to_sql.should(
        eq %(SELECT * FROM "users" WHERE ((a = 1) OR (b = 2)))
      )
      # First OR WHERE acts as a simple WHERE:
      Clear::SQL.select.from(:users).or_where("a = ?", 1).or_where("b = ?", 2).to_sql.should(
        eq %(SELECT * FROM "users" WHERE ((a = 1) OR (b = 2)))
      )
    end

    it "manages ranges" do
      Clear::SQL.select.from(:users).where({x: 1..4}).to_sql
        .should eq "SELECT * FROM \"users\" WHERE (\"x\" >= 1 AND \"x\" <= 4)"

      Clear::SQL.select.from(:users).where({x: 1...4}).to_sql
        .should eq "SELECT * FROM \"users\" WHERE (\"x\" >= 1 AND \"x\" < 4)"
    end

    it "can prepare query" do
      r = Clear::SQL.select.from(:users).where("a LIKE ?", "hello")
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE a LIKE 'hello'"

    end

    it "raises exception with prepared query" do
      expect_raises Clear::SQL::QueryBuildingError do
        Clear::SQL.select.from(:users).where("a LIKE ? AND b = ?", "hello")
      end
    end

    it "can prepare query with tuple" do
      r = Clear::SQL.select.from(:users).where("a LIKE :hello AND b LIKE :world",
        hello: "h", world: "w")
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE a LIKE 'h' AND b LIKE 'w'"
    end

    it "raises exception if a tuple element is not found" do
      expect_raises Clear::SQL::QueryBuildingError do
        Clear::SQL.select.from(:users).where("a LIKE :halo AND b LIKE :world", hello: "h", world: "w")
      end

      expect_raises Clear::SQL::QueryBuildingError do
        Clear::SQL.select.from(:users).or_where("a LIKE :halo AND b LIKE :world", hello: "h", world: "w")
      end
    end

    it "can prepare group by query" do
      Clear::SQL.select.select("role").from(:users).group_by(:role).order_by(:role).to_sql.should eq \
        "SELECT role FROM \"users\" GROUP BY \"role\" ORDER BY \"role\" ASC"
    end

    it "can use different comparison and arithmetic operators" do
      r = Clear::SQL.select.from(:users).where { users.id > 1 }
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" > 1)"
      r = Clear::SQL.select.from(:users).where { users.id < 1 }
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" < 1)"
      r = Clear::SQL.select.from(:users).where { users.id >= 1 }
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" >= 1)"
      r = Clear::SQL.select.from(:users).where { users.id <= 1 }
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" <= 1)"
      r = Clear::SQL.select.from(:users).where { users.id * 2 == 1 }
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE ((\"users\".\"id\" * 2) = 1)"
      r = Clear::SQL.select.from(:users).where { users.id / 2 == 1 }
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE ((\"users\".\"id\" / 2) = 1)"
      r = Clear::SQL.select.from(:users).where { users.id + 2 == 1 }
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE ((\"users\".\"id\" + 2) = 1)"
      r = Clear::SQL.select.from(:users).where { users.id - 2 == 1 }
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE ((\"users\".\"id\" - 2) = 1)"
      r = Clear::SQL.select.from(:users).where { -users.id < -1000 }
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE (-\"users\".\"id\" < -1000)"
    end

    it "can use expression engine equal" do
      r = Clear::SQL.select.from(:users).where { users.id == var("test") }
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" = \"test\")"
    end

    it "can use expression engine not equals" do
      r = Clear::SQL.select.from(:users).where { users.id != 1 }
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" <> 1)"
    end

    it "can use expression engine not null" do
      r = Clear::SQL.select.from(:users).where { users.id != nil }
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" IS NOT NULL)"
    end

    it "can use expression engine null" do
      r = Clear::SQL.select.from(:users).where { users.id == nil }
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" IS NULL)"
    end

    it "can stack with `AND` operator" do
      now = Time.local
      r = Clear::SQL.select.from(:users).where { users.id == nil }.where {
        var("users", "updated_at") >= now
      }
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" IS NULL) " +
                        "AND (\"users\".\"updated_at\" >= #{Clear::Expression[now]})"
    end

    it "can use subquery into where clause" do
      r = Clear::SQL.select.from(:users).where { users.id.in?(complex_query.clear_select.select(:id)) }
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE \"users\".\"id\" IN (" +
                        "SELECT \"id\" FROM \"users\" INNER JOIN \"role_users\" ON " +
                        "(\"role_users\".\"user_id\" = \"users\".\"id\") INNER JOIN \"roles\"" +
                        " ON (\"role_users\".\"role_id\" = \"roles\".\"id\") WHERE \"role\" IN" +
                        " ('admin', 'superadmin') ORDER BY \"priority\" DESC, " +
                        "\"name\" ASC LIMIT 50 OFFSET 50)"
    end

    it "can build locks" do
      r = Clear::SQL.select.from(:users).with_lock("FOR UPDATE")
      r.to_sql.should eq "SELECT * FROM \"users\" FOR UPDATE"

      r = Clear::SQL.select.from(:users).with_lock("FOR SHARE")
      r.to_sql.should eq "SELECT * FROM \"users\" FOR SHARE"
    end

    it "can join lateral" do
      Clear::SQL::SelectQuery.new.from(:a)
        .inner_join(:b, lateral: true) { a.b_id == b.id }.to_sql
        .should eq %(SELECT * FROM "a" INNER JOIN LATERAL "b" ON ("a"."b_id" = "b"."id"))
    end

    it "can use & as AND and | as OR" do
      r = Clear::SQL.select.from(:users).where {
        ((raw("users.id") > 100) & (raw("users.visible") == true)) |
          (raw("users.role") == "superadmin")
      }

      r.to_sql.should eq "SELECT * FROM \"users\" WHERE (((users.id > 100) " +
                        "AND (users.visible = TRUE)) OR (users.role = 'superadmin'))"
    end

    it "can check presence into array" do
      r = Clear::SQL.select.from(:users).where { raw("users.id").in?([1, 2, 3, 4]) }
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE users.id IN (1, 2, 3, 4)"
    end

    it "can check presence into range" do
      # Simple number
      Clear::SQL.select.from(:users).where { users.id.in?(1..3) }.to_sql
        .should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" >= 1 AND \"users\".\"id\" <= 3)"

      # Date range.
      range = 2.day.ago..1.day.ago

      Clear::SQL.select.from(:users).where { created_at.in?(range) }.to_sql
        .should eq "SELECT * FROM \"users\" WHERE " +
                  "(\"created_at\" >= #{Clear::Expression[range.begin]} AND" +
                  " \"created_at\" <= #{Clear::Expression[range.end]})"

      # Exclusive range
      Clear::SQL.select.from(:users).where { users.id.in?(1...3) }.to_sql
        .should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" >= 1" +
                  " AND \"users\".\"id\" < 3)"
    end
  end
end