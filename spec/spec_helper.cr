require "spec"

require "../src/clear"

# Avoiding migration number collisions
MIGRATION_SPEC_MIGRATION_UID = 0x0100000000000000_u64
MIGRATION_SPEC_MODEL_UID     = 0x0200000000000000_u64

class ::Crypto::Bcrypt::Password
  # Redefine the default cost to 4 (the minimum allowed) to accelerate greatly the tests.
  DEFAULT_COST = 4
end

DB_ENV = ENV.fetch("ENV", "local")

DB_NAME = ENV.fetch("DB_NAME", "clear_db")

def initdb
  if DB_ENV == "local"
    system("echo \"DROP DATABASE IF EXISTS clear_spec;\" | psql -U postgres 1>/dev/null")
    system("echo \"CREATE DATABASE clear_spec;\" | psql -U postgres 1>/dev/null")

    system("echo \"DROP DATABASE IF EXISTS clear_secondary_spec;\" | psql -U postgres 1>/dev/null")
    system("echo \"CREATE DATABASE clear_secondary_spec;\" | psql -U postgres 1>/dev/null")
    system("echo \"CREATE TABLE models_post_stats (id serial PRIMARY KEY, post_id INTEGER);\" | psql -U postgres clear_secondary_spec 1>/dev/null")
  elsif DB_ENV == "docker"
    system("docker exec -it #{DB_NAME} psql -c 'DROP DATABASE IF EXISTS clear_spec;' -U postgres")
    system("docker exec -it #{DB_NAME} psql -c 'CREATE DATABASE clear_spec;' -U postgres")

    system("docker exec -it #{DB_NAME} psql -c 'DROP DATABASE IF EXISTS clear_secondary_spec;' -U postgres")
    system("docker exec -it #{DB_NAME} psql -c 'CREATE DATABASE clear_secondary_spec;' -U postgres")
    system("docker exec -it #{DB_NAME} psql -c 'CREATE TABLE models_post_stats (id serial PRIMARY KEY, post_id INTEGER);' -U postgres clear_secondary_spec")
  else
    raise ArgumentError.new("Invalid ENV value")
  end

  Clear::SQL.init("postgres://postgres:password@localhost:5432/clear_spec?retry_attempts=1&retry_delay=1&initial_pool_size=5")
  Clear::SQL.init("secondary", "postgres://postgres:password@localhost:5432/clear_secondary_spec?retry_attempts=1&retry_delay=1&initial_pool_size=5")
end

Spec.before_suite do
  {% if flag?(:quiet) %}
    ::Log.setup(:warning)
  {% else %}
    ::Log.setup(:debug)
  {% end %}
end

def reinit_migration_manager
  Clear::Migration::Manager.instance.reinit!
end

def temporary(&block)
  Clear::SQL.with_savepoint do
    yield
    Clear::SQL.rollback
  end
end

# Structure used to call the compile-time tests.
struct CrystalCall
  property stdout = IO::Memory.new
  property stderr = IO::Memory.new
  property status

  def initialize(script, is_spec = false)
    @status = Process.run("crystal", [is_spec ? "spec" : nil, "spec/data/compile_time/#{script}.cr", "--error-trace"].compact,
      output: stdout, error: stderr)
  end

  def stderr_contains?(regexp)
    !!(stderr.to_s =~ regexp)
  end

  def debug
    puts stdout
    puts stderr
  end
end

def compile_and_run(script)
  CrystalCall.new(script)
end

def compile_and_spec(script)
  CrystalCall.new(script, true)
end

initdb
