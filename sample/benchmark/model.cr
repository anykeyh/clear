require "../src/clear"
require "benchmark"

class TimeRange
  include Clear::Model

  column user_id : Int32
  column starts_at : Time
  column ends_at : Time?

  self.table = "user_time_ranges"
end

puts "Starting benchmarking, total to fetch =" +
     " #{Clear::SQL.select("COUNT(*) as c").from("user_time_ranges").scalar(Int64)} records"
Benchmark.ips(warmup: 2, calculation: 5) do |x|
  x.report("Simple load") { TimeRange.query.limit(100000).to_a }
  x.report("With cursor") { a = [] of TimeRange; TimeRange.query.limit(100000).each_with_cursor { |x| a << x } }
  x.report("With attributes") { TimeRange.query.limit(100000).to_a(fetch_columns: true) }
  x.report("With attributes and cursor") { a = [] of TimeRange; TimeRange.query.limit(100000).each_with_cursor(fetch_columns: true) { |x| a << x } }
  x.report("SQL only") { a = [] of Hash(String, ::Clear::SQL::Any); TimeRange.query.limit(100000).fetch { |h| a << h } }
end
