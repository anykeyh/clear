require "spec"

require "../../src/clear/sql/sql"

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
                  .join(:role_users) { var("role_users.user_id") == users.id }
                  .join(:roles) { var("role_users.role_id") == var("roles.id") }
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
        r.to_delete.to_sql.should eq "DELETE FROM users WHERE (users.id > 1000)"
      end

      describe "the SELECT clause" do
        it "can select wildcard *" do
          r = select_request.select("*")
          r.to_sql.should eq "SELECT *"
        end

        it "can select any string" do
          r = select_request.select("1")
          r.to_sql.should eq "SELECT 1"
        end

        it "can select using variables" do
          r = select_request.select({sum: "SUM(quantity)", count: "COUNT(*)"})
          r.to_sql.should eq "SELECT SUM(quantity) AS sum, COUNT(*) AS count"
        end

        it "can select using multiple strings" do
          r = select_request.select("user_id AS uid", "column AS some_cool_stuff")
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

      describe "the FROM clause" do
        it "can build simple from" do
          r = select_request.from(:users)
          r.to_sql.should eq "SELECT * FROM users"
        end

        it "can build multiple from" do
          r = select_request.from(:users, :posts)
          r.to_sql.should eq "SELECT * FROM users, posts"
        end

        it "can build named from" do
          r = select_request.from({customers: "users"})
          r.to_sql.should eq "SELECT * FROM users AS customers"
        end

        it "raise works with subquery as from" do
          r = select_request.from({q: complex_query})
          r.to_sql.should eq "SELECT * FROM ( #{complex_query.to_sql} ) q"
        end

        it "can write from by string" do
          r = select_request.from("(SELECT * FROM users LIMIT 10) users")
          r.to_sql.should eq "SELECT * FROM (SELECT * FROM users LIMIT 10) users"
        end

        it "can stack" do
          r = select_request.from("x").from("y")
          r.to_sql.should eq "SELECT * FROM x, y"
        end

        it "can be cleared" do
          r = select_request.from("x").clear_from.from("y")
          r.to_sql.should eq "SELECT * FROM y"
        end

        it "raise error if from subquery is not named" do
          expect_raises Clear::SQL::QueryBuildingError do
            r = select_request.from(complex_query)
            r.to_sql
          end
        end
      end

      describe "the WHERE clause" do
        context "using simple engine" do
          it "can use simple equals" do
            r = select_request.from(:users).where({user_id: 1})
            r.to_sql.should eq "SELECT * FROM users WHERE user_id = 1"
          end

          it "can use `in` operators in case of array" do
            r = select_request.from(:users).where({user_id: [1, 2, 3, 4, "hello"]})
            r.to_sql.should eq "SELECT * FROM users WHERE user_id IN (1, 2, 3, 4, 'hello')"
          end

          it "can write where with string" do
            r = select_request.from(:users).where("a = b")
            r.to_sql.should eq "SELECT * FROM users WHERE a = b"
          end

          it "can prepare query" do
            r = select_request.from(:users).where("a LIKE ?", ["hello"])
            r.to_sql.should eq "SELECT * FROM users WHERE a LIKE 'hello'"
          end

          it "raises exception with prepared query" do
            expect_raises Clear::SQL::QueryBuildingError do
              r = select_request.from(:users).where("a LIKE ? AND b = ?", ["hello"])
            end
          end

          it "can prepare query with tuple" do
            r = select_request.from(:users).where("a LIKE :hello AND b LIKE :world",
              {hello: "h", world: "w"})
            r.to_sql.should eq "SELECT * FROM users WHERE a LIKE 'h' AND b LIKE 'w'"
          end

          it "raises exception if a tuple element is not found" do
            expect_raises Clear::SQL::QueryBuildingError do
              r = select_request.from(:users).where("a LIKE :halo AND b LIKE :world",
                {hello: "h", world: "w"})
            end
          end
        end

        context "using expression engine" do
          it "can use different comparison and arithmetic operators" do
            r = select_request.from(:users).where { users.id > 1 }
            r.to_sql.should eq "SELECT * FROM users WHERE (users.id > 1)"
            r = select_request.from(:users).where { users.id < 1 }
            r.to_sql.should eq "SELECT * FROM users WHERE (users.id < 1)"
            r = select_request.from(:users).where { users.id >= 1 }
            r.to_sql.should eq "SELECT * FROM users WHERE (users.id >= 1)"
            r = select_request.from(:users).where { users.id <= 1 }
            r.to_sql.should eq "SELECT * FROM users WHERE (users.id <= 1)"
            r = select_request.from(:users).where { users.id * 2 == 1 }
            r.to_sql.should eq "SELECT * FROM users WHERE ((users.id * 2) = 1)"
            r = select_request.from(:users).where { users.id / 2 == 1 }
            r.to_sql.should eq "SELECT * FROM users WHERE ((users.id / 2) = 1)"
            r = select_request.from(:users).where { users.id + 2 == 1 }
            r.to_sql.should eq "SELECT * FROM users WHERE ((users.id + 2) = 1)"
            r = select_request.from(:users).where { users.id - 2 == 1 }
            r.to_sql.should eq "SELECT * FROM users WHERE ((users.id - 2) = 1)"
            r = select_request.from(:users).where { -users.id < -1000 }
            r.to_sql.should eq "SELECT * FROM users WHERE (-users.id < -1000)"
          end

          it "can use expression engine equal" do
            r = select_request.from(:users).where { users.id == var("test") }
            r.to_sql.should eq "SELECT * FROM users WHERE (users.id = test)"
          end

          it "can use expression engine not equals" do
            r = select_request.from(:users).where { users.id != 1 }
            r.to_sql.should eq "SELECT * FROM users WHERE (users.id <> 1)"
          end

          it "can use expression engine not null" do
            r = select_request.from(:users).where { users.id != nil }
            r.to_sql.should eq "SELECT * FROM users WHERE (users.id IS NOT NULL)"
          end

          it "can use expression engine null" do
            r = select_request.from(:users).where { users.id == nil }
            r.to_sql.should eq "SELECT * FROM users WHERE (users.id IS NULL)"
          end

          it "can stack with `AND` operator" do
            now = Time.now
            r = select_request.from(:users).where { users.id == nil }.where { var("users.updated_at") >= now }
            r.to_sql.should eq "SELECT * FROM users WHERE (users.id IS NULL) " +
                               "AND (users.updated_at >= #{Clear::Expression[now]})"
          end

          it "can use subquery into where clause" do
            r = select_request.from(:users).where { users.id.in?(complex_query.clear_select.select(:id)) }
            r.to_sql.should eq "SELECT * FROM users WHERE users.id IN ( " +
                               "SELECT id FROM users INNER JOIN role_users ON " +
                               "((role_users.user_id = users.id)) INNER JOIN roles" +
                               " ON ((role_users.role_id = roles.id)) WHERE role IN" +
                               " ('admin', 'superadmin') ORDER BY priority DESC, " +
                               "name ASC LIMIT 50 OFFSET 50 )"
          end

          it "can build locks" do
            r = select_request.from(:users).with_lock("FOR UPDATE")
            r.to_sql.should eq "SELECT * FROM users FOR UPDATE"

            r = select_request.from(:users).with_lock("FOR SHARE")
            r.to_sql.should eq "SELECT * FROM users FOR SHARE"
          end

          it "can use & as AND and | as OR" do
            r = select_request.from(:users).where {
              ((raw("users.id") > 100) & (raw("users.visible") == true)) | (raw("users.role") == "superadmin")
            }

            r.to_sql.should eq "SELECT * FROM users WHERE (((users.id > 100) " +
                               "AND (users.visible = TRUE)) OR (users.role = 'superadmin'))"
          end

          it "can check presence into array" do
            r = select_request.from(:users).where { raw("users.id").in?([1, 2, 3, 4]) }
            r.to_sql.should eq "SELECT * FROM users WHERE users.id IN (1, 2, 3, 4)"
          end
        end
      end
    end
  end
end
