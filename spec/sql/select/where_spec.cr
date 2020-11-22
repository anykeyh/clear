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

      # check escaping `::`
      r = Clear::SQL.select.from(:users).where("a::text LIKE :hello",
        hello: "h")
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE a::text LIKE 'h'"

      # check escaping the first character because of the regexp solution I used
      r = Clear::SQL.select.from(:users).where(":text", text: "ok")
      r.to_sql.should eq "SELECT * FROM \"users\" WHERE 'ok'"
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

    describe "where expressions" do
      it "where.where" do
        now = Time.local
        r = Clear::SQL.select.from(:users).where { users.id == nil }.where {
          var("users", "updated_at") >= now
        }
        r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" IS NULL) " +
                           "AND (\"users\".\"updated_at\" >= #{Clear::Expression[now]})"
      end

      it "where.or_where" do
        now = Time.local
        r = Clear::SQL.select.from(:users).where { users.id == nil }.or_where {
          var("users", "updated_at") >= now
        }
        r.to_sql.should eq "SELECT * FROM \"users\" WHERE ((\"users\".\"id\" IS NULL) " +
                           "OR (\"users\".\"updated_at\" >= #{Clear::Expression[now]}))"
      end

      it "op(:&)/op(:|)" do
        r = Clear::SQL.select.from(:users).where {
          ((raw("users.id") > 100) & (raw("users.visible") == true)) |
            (raw("users.role") == "superadmin")
        }

        r.to_sql.should eq "SELECT * FROM \"users\" WHERE (((users.id > 100) " +
                           "AND (users.visible = TRUE)) OR (users.role = 'superadmin'))"
      end

      it "between(a, b)" do
        Clear::SQL.select.where { x.between(1, 2) }
          .to_sql.should eq(%[SELECT * WHERE ("x" BETWEEN 1 AND 2)])

        Clear::SQL.select.where { not(x.between(1, 2)) }
          .to_sql.should eq(%[SELECT * WHERE NOT ("x" BETWEEN 1 AND 2)])
      end

      it "custom functions" do
        Clear::SQL.select.where { ops_transform(x, "string", raw("INTERVAL '2 seconds'")) }
          .to_sql.should eq(%[SELECT * WHERE ops_transform("x", 'string', INTERVAL '2 seconds')])
      end

      it "in?(array)" do
        Clear::SQL.select.where { x.in?([1, 2, 3, 4]) }
          .to_sql.should eq(%[SELECT * WHERE "x" IN (1, 2, 3, 4)])

        Clear::SQL.select.where { x.in?({1, 2, 3, 4}) }
          .to_sql.should eq(%[SELECT * WHERE "x" IN (1, 2, 3, 4)])
      end

      it "in?(range)" do
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

      it "in?(sub_query)" do
        sub_query = Clear::SQL.select("id").from("users")
        Clear::SQL.select.where { x.in?(sub_query) }
          .to_sql.should eq(%[SELECT * WHERE "x" IN (SELECT id FROM users)])
      end

      it "unary minus" do
        Clear::SQL.select.where { -x > 2 }
          .to_sql.should eq(%[SELECT * WHERE (-"x" > 2)])
      end

      it "not()" do
        Clear::SQL.select.where { not(raw("TRUE")) }
          .to_sql.should eq(%[SELECT * WHERE NOT TRUE])

        Clear::SQL.select.where { ~(raw("TRUE")) }
          .to_sql.should eq(%[SELECT * WHERE NOT TRUE])
      end

      it "nil" do
        Clear::SQL.select.where { x == nil }
          .to_sql.should eq(%[SELECT * WHERE ("x" IS NULL)])
        Clear::SQL.select.where { x != nil }
          .to_sql.should eq(%[SELECT * WHERE ("x" IS NOT NULL)])
      end

      it "raw()" do
        Clear::SQL.select.where { raw("Anything") }
          .to_sql.should eq(%[SELECT * WHERE Anything])

        Clear::SQL.select.where { raw("x > ?", 1) }
          .to_sql.should eq(%[SELECT * WHERE x > 1])

        Clear::SQL.select.where { raw("x > :num", num: 2) }
          .to_sql.should eq(%[SELECT * WHERE x > 2])
      end

      it "var()" do
        Clear::SQL.select.where { var("public", "users", "id") < 1000 }
          .to_sql.should eq(%[SELECT * WHERE ("public"."users"."id" < 1000)])
      end
    end
  end
end
