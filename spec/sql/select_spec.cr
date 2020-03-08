require "spec"

require "../spec_helper"

module SelectSpec
  extend self

  def select_request
    Clear::SQL::SelectQuery.new
  end

  def one_request
    select_request
      .select("MAX(updated_at)")
      .from(:users)
  end

  def complex_query
    select_request.from(:users)
      .join(:role_users) { var("role_users", "user_id") == users.id }
      .join(:roles) { var("role_users", "role_id") == var("roles", "id") }
      .where({role: ["admin", "superadmin"]})
      .order_by({priority: :desc, name: :asc})
      .limit(50)
      .offset(50)
  end

  describe "Clear::SQL" do
    describe "SelectQuery" do
      it "can create a simple request" do
        r = select_request
        r.to_sql.should eq "SELECT *"
      end

      it "can duplicate itself" do
        cq_2 = complex_query.dup
        cq_2.to_sql.should eq complex_query.to_sql
      end

      it "can transfert to delete method" do
        r = select_request.select("*").from(:users).where { raw("users.id") > 1000 }
        r.to_delete.to_sql.should eq "DELETE FROM \"users\" WHERE (users.id > 1000)"
      end

      it "can transfert to update method" do
        r = select_request.select("*").from(:users).where { var("users","id") > 1000 }
        r.to_update.set(x: 1).to_sql.should eq "UPDATE \"users\" SET \"x\" = 1 WHERE (\"users\".\"id\" > 1000)"
      end

      describe "the SELECT clause" do
        it "can select wildcard *" do
          r = select_request.select("*")
          r.to_sql.should eq "SELECT *"
        end

        it "can select distinct" do
          r = select_request.distinct.select("*")
          r.to_sql.should eq "SELECT DISTINCT *"

          r = select_request.distinct.select("a", "b", "c")
          r.to_sql.should eq "SELECT DISTINCT a, b, c"

          r = select_request.distinct.select(:first_name, :last_name, :id)
          r.to_sql.should eq %(SELECT DISTINCT "first_name", "last_name", "id")
        end

        it "can select any string" do
          r = select_request.select("1")
          r.to_sql.should eq "SELECT 1"
        end

        it "can select using variables" do
          r = select_request.select("SUM(quantity) AS sum", "COUNT(*) AS count")
          # No escape with string, escape must be done manually
          r.to_sql.should eq "SELECT SUM(quantity) AS sum, COUNT(*) AS count"
        end

        it "can select using named tuple" do
          r = select_request.select(uid: "user_id", some_cool_stuff: "column")
          r.to_sql.should eq "SELECT user_id AS uid, column AS some_cool_stuff"
        end

        it "can reset the select" do
          r = select_request.select("1").clear_select.select("2")
          r.to_sql.should eq "SELECT 2"
        end

        it "can select a subquery" do
          r = select_request.select({max_updated_at: one_request})
          r.to_sql.should eq "SELECT ( #{one_request.to_sql} ) AS max_updated_at"
        end
      end

      describe "the ORDER BY clause" do
        it "can add NULLS FIRST and NULLS LAST" do
          r = select_request.from("users").order_by("email", "ASC", "NULLS LAST")
          r.to_sql.should eq "SELECT * FROM users ORDER BY email ASC NULLS LAST"
        end
      end

      describe "SelectQuery#with_cte" do
        it "can build request with CTE" do
          # Simple CTE
          cte = select_request.from(:users_info).where("x > 10")
          sql = select_request.from(:ui).with_cte("ui", cte).to_sql
          sql.should eq %[WITH ui AS (SELECT * FROM "users_info" WHERE x > 10) SELECT * FROM "ui"]

          # Complex CTE
          cte1 = select_request.from(:users_info).where { a == b }
          cte2 = select_request.from(:just_another_table).where { users_infos.x == just_another_table.w }
          sql = select_request.with_cte({ui: cte1, at: cte2}).from(:at).to_sql
          sql.should eq %[WITH ui AS (SELECT * FROM "users_info" WHERE ("a" = "b")),] +
                        %[ at AS (SELECT * FROM "just_another_table" WHERE (] +
                        %["users_infos"."x" = "just_another_table"."w")) SELECT * FROM "at"]
        end
      end

      describe "the WHERE clause" do
        context "using simple engine" do
          it "can use simple equals" do
            r = select_request.from(:users).where({user_id: 1})
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"user_id\" = 1)"

            r = select_request.from(:users).where(user_id: 1)
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"user_id\" = 1)"
          end

          it "can use simple equals with nil" do
            r = select_request.from(:users).where({user_id: nil})
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"user_id\" IS NULL)"
          end

          it "can use or_where" do
            select_request.from(:users).where("a = ?", {1}).or_where("b = ?", {2}).to_sql.should(
              eq %(SELECT * FROM "users" WHERE ((a = 1) OR (b = 2)))
            )

            # First OR WHERE acts as a simple WHERE:
            select_request.from(:users).or_where("a = ?", {1}).or_where("b = ?", {2}).to_sql.should(
              eq %(SELECT * FROM "users" WHERE ((a = 1) OR (b = 2)))
            )
          end


          it "can use `in` operators in case of array" do
            r = select_request.from(:users).where({user_id: [1, 2, 3, 4, "hello"]})
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE \"user_id\" IN (1, 2, 3, 4, 'hello')"
          end

          it "can write where with string" do
            r = select_request.from(:users).where("a = b")
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE a = b"
          end

          it "manages ranges" do
            select_request.from(:users).where({x: 1..4}).to_sql
              .should eq "SELECT * FROM \"users\" WHERE (\"x\" >= 1 AND \"x\" <= 4)"

            select_request.from(:users).where({x: 1...4}).to_sql
              .should eq "SELECT * FROM \"users\" WHERE (\"x\" >= 1 AND \"x\" < 4)"
          end

          it "can prepare query" do
            r = select_request.from(:users).where("a LIKE ?", ["hello"])
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE a LIKE 'hello'"

            r = select_request.from(:users).where("a LIKE ?", {"hello"})
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE a LIKE 'hello'"
          end

          it "raises exception with prepared query" do
            expect_raises Clear::SQL::QueryBuildingError do
              select_request.from(:users).where("a LIKE ? AND b = ?", ["hello"])
            end
          end

          it "can prepare query with tuple" do
            r = select_request.from(:users).where("a LIKE :hello AND b LIKE :world",
              {hello: "h", world: "w"})
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE a LIKE 'h' AND b LIKE 'w'"
          end

          it "raises exception if a tuple element is not found" do
            expect_raises Clear::SQL::QueryBuildingError do
              select_request.from(:users).where("a LIKE :halo AND b LIKE :world",
                {hello: "h", world: "w"})
            end

            expect_raises Clear::SQL::QueryBuildingError do
              select_request.from(:users).or_where("a LIKE :halo AND b LIKE :world",
                {hello: "h", world: "w"})
            end
          end

          it "can prepare group by query" do
            select_request.select("role").from(:users).group_by(:role).order_by(:role).to_sql.should eq \
              "SELECT role FROM \"users\" GROUP BY \"role\" ORDER BY \"role\" ASC"
          end
        end

        context "using expression engine" do
          it "can use different comparison and arithmetic operators" do
            r = select_request.from(:users).where { users.id > 1 }
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" > 1)"
            r = select_request.from(:users).where { users.id < 1 }
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" < 1)"
            r = select_request.from(:users).where { users.id >= 1 }
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" >= 1)"
            r = select_request.from(:users).where { users.id <= 1 }
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" <= 1)"
            r = select_request.from(:users).where { users.id * 2 == 1 }
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE ((\"users\".\"id\" * 2) = 1)"
            r = select_request.from(:users).where { users.id / 2 == 1 }
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE ((\"users\".\"id\" / 2) = 1)"
            r = select_request.from(:users).where { users.id + 2 == 1 }
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE ((\"users\".\"id\" + 2) = 1)"
            r = select_request.from(:users).where { users.id - 2 == 1 }
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE ((\"users\".\"id\" - 2) = 1)"
            r = select_request.from(:users).where { -users.id < -1000 }
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE (-\"users\".\"id\" < -1000)"
          end

          it "can use expression engine equal" do
            r = select_request.from(:users).where { users.id == var("test") }
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" = \"test\")"
          end

          it "can use expression engine not equals" do
            r = select_request.from(:users).where { users.id != 1 }
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" <> 1)"
          end

          it "can use expression engine not null" do
            r = select_request.from(:users).where { users.id != nil }
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" IS NOT NULL)"
          end

          it "can use expression engine null" do
            r = select_request.from(:users).where { users.id == nil }
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" IS NULL)"
          end

          it "can stack with `AND` operator" do
            now = Time.local
            r = select_request.from(:users).where { users.id == nil }.where {
              var("users", "updated_at") >= now
            }
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" IS NULL) " +
                               "AND (\"users\".\"updated_at\" >= #{Clear::Expression[now]})"
          end

          it "can use subquery into where clause" do
            r = select_request.from(:users).where { users.id.in?(complex_query.clear_select.select(:id)) }
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE \"users\".\"id\" IN (" +
                               "SELECT \"id\" FROM \"users\" INNER JOIN \"role_users\" ON " +
                               "(\"role_users\".\"user_id\" = \"users\".\"id\") INNER JOIN \"roles\"" +
                               " ON (\"role_users\".\"role_id\" = \"roles\".\"id\") WHERE \"role\" IN" +
                               " ('admin', 'superadmin') ORDER BY priority DESC, " +
                               "name ASC LIMIT 50 OFFSET 50)"
          end

          it "can build locks" do
            r = select_request.from(:users).with_lock("FOR UPDATE")
            r.to_sql.should eq "SELECT * FROM \"users\" FOR UPDATE"

            r = select_request.from(:users).with_lock("FOR SHARE")
            r.to_sql.should eq "SELECT * FROM \"users\" FOR SHARE"
          end

          it "can join lateral" do
            Clear::SQL::SelectQuery.new.from(:a)
              .inner_join(:b, lateral: true) { a.b_id == b.id }.to_sql
              .should eq %(SELECT * FROM "a" INNER JOIN LATERAL "b" ON ("a"."b_id" = "b"."id"))
          end

          it "can use & as AND and | as OR" do
            r = select_request.from(:users).where {
              ((raw("users.id") > 100) & (raw("users.visible") == true)) |
                (raw("users.role") == "superadmin")
            }

            r.to_sql.should eq "SELECT * FROM \"users\" WHERE (((users.id > 100) " +
                               "AND (users.visible = TRUE)) OR (users.role = 'superadmin'))"
          end

          it "can check presence into array" do
            r = select_request.from(:users).where { raw("users.id").in?([1, 2, 3, 4]) }
            r.to_sql.should eq "SELECT * FROM \"users\" WHERE users.id IN (1, 2, 3, 4)"
          end

          it "can check presence into range" do
            # Simple number
            select_request.from(:users).where { users.id.in?(1..3) }.to_sql
              .should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" >= 1 AND \"users\".\"id\" <= 3)"

            # Date range.
            range = 2.day.ago..1.day.ago

            select_request.from(:users).where { created_at.in?(range) }.to_sql
              .should eq "SELECT * FROM \"users\" WHERE " +
                         "(\"created_at\" >= #{Clear::Expression[range.begin]} AND" +
                         " \"created_at\" <= #{Clear::Expression[range.end]})"

            # Exclusive range
            select_request.from(:users).where { users.id.in?(1...3) }.to_sql
              .should eq "SELECT * FROM \"users\" WHERE (\"users\".\"id\" >= 1" +
                         " AND \"users\".\"id\" < 3)"
          end
        end
      end

      describe "WithPagination" do
        context "when there's 1901902 records and limit of 25" do
          it "sets the per_page to 25" do
            r = select_request.from(:users).offset(0).limit(25)
            r.total_entries = 1_901_902_i64
            r.per_page.should eq 25
          end

          it "returns 1 for current_page with no limit set" do
            r = select_request.from(:users)
            r.total_entries = 1_901_902_i64
            r.current_page.should eq 1
          end

          it "returns 5 for current_page when offset is 100" do
            r = select_request.from(:users).offset(100).limit(25)
            r.total_entries = 1_901_902_i64
            r.current_page.should eq 5
          end

          it "returns 1 for total_pages when there's no limit" do
            r = select_request.from(:users)
            r.total_entries = 1_901_902_i64
            r.total_pages.should eq 1
          end

          it "returns 76077 total_pages when 25 per_page" do
            r = select_request.from(:users).offset(100).limit(25)
            r.total_entries = 1_901_902_i64
            r.total_pages.should eq 76_077
          end

          it "returns 4 as previous_page when on page 5" do
            r = select_request.from(:users).offset(100).limit(25)
            r.total_entries = 1_901_902_i64
            r.current_page.should eq 5
            r.previous_page.should eq 4
          end

          it "returns nil for previous_page when on page 1" do
            r = select_request.from(:users).offset(0).limit(25)
            r.total_entries = 1_901_902_i64
            r.current_page.should eq 1
            r.previous_page.should eq nil
          end

          it "returns 6 as next_page when on page 5" do
            r = select_request.from(:users).offset(100).limit(25)
            r.total_entries = 1_901_902_i64
            r.current_page.should eq 5
            r.next_page.should eq 6
          end

          it "returns nil for next_page when on page 76077" do
            r = select_request.from(:users).offset(1_901_900).limit(25)
            r.total_entries = 1_901_902_i64
            r.current_page.should eq 76_077
            r.next_page.should eq nil
          end

          it "returns true for out_of_bounds? when current_page is 76078" do
            r = select_request.from(:users).offset(1_901_925).limit(25)
            r.total_entries = 1_901_902_i64
            r.current_page.should eq 76_078
            r.out_of_bounds?.should eq true
          end

          it "returns false for out_of_bounds? when current_page is in normal range" do
            r = select_request.from(:users).offset(925).limit(25)
            r.total_entries = 1_901_902_i64
            r.out_of_bounds?.should eq false
          end
        end
      end
    end
  end
end
