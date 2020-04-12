require "../../src/clear"
require "benchmark"

# Initialize the connection
`echo "DROP DATABASE IF EXISTS benchmark_clear;" | psql -U postgres`
`echo "CREATE DATABASE benchmark_clear;" | psql -U postgres`
Clear::SQL.init("postgres://postgres@localhost/benchmark_clear")

init = <<-SQL
  CREATE TABLE benchmark (id serial PRIMARY KEY NOT NULL, y int);
  CREATE INDEX benchmark_y ON benchmark (y);

  INSERT INTO benchmark
  SELECT i AS x, 2*i as y
  FROM generate_series(1, 1000000) AS i;
end
SQL

init.split(";").each { |sql| Clear::SQL.execute(sql) }

class BenchmarkModel
  include Clear::Model

  self.table = "benchmark"

  with_serial_pkey

  column y : Int32
end

puts "Starting benchmarking, total to fetch =" +
     " #{BenchmarkModel.query.count} records"
Benchmark.ips(warmup: 2, calculation: 5) do |x|
  x.report("With Model: Simple load 100k") { BenchmarkModel.query.limit(100_000).to_a }
  x.report("With Model: With cursor") { a = [] of BenchmarkModel; BenchmarkModel.query.limit(100_000).each_with_cursor { |o| a << o } }
  x.report("With Model: With attributes") { BenchmarkModel.query.limit(100_000).to_a(fetch_columns: true) }
  x.report("With Model: With attributes and cursor") { a = [] of BenchmarkModel; BenchmarkModel.query.limit(100_000).each_with_cursor(fetch_columns: true) { |h| a << h } }
  x.report("Using: Pluck") { BenchmarkModel.query.limit(100_000).pluck("y") }
  x.report("Hash from SQL only") { a = [] of Hash(String, ::Clear::SQL::Any); BenchmarkModel.query.limit(100_000).fetch { |h| a << h } }
end
