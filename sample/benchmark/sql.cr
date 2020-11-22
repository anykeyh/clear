require "../src/clear/sql"
require "benchmark"

def complex_query
  Clear::SQL.select.from(:users)
    .join(:role_users) { role_users.user_id == users.id }
    .join(:roles) { role_users.role_id == roles.id }
    .where({role: ["admin", "superadmin"]})
    .order_by({priority: :desc, name: :asc})
    .limit(50)
    .offset(50)
end

Benchmark.ips(warmup: 2, calculation: 3) do |x|
  x.report("complex query building") { complex_query.to_sql }
end
