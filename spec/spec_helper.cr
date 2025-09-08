require "spec"

require "../src/clear"

# Avoiding migration number collisions
MIGRATION_SPEC_MIGRATION_UID = 0x0100000000000000_u64
MIGRATION_SPEC_MODEL_UID     = 0x0200000000000000_u64

class ::Crypto::Bcrypt::Password
  # Redefine the default cost to 4 (the minimum allowed) to accelerate greatly the tests.
  DEFAULT_COST = 4
end

def initdb
  # Recreate test database to have a f
  system("bin/prepare_test_db.sh")

  db_user = ENV.fetch("DB_USER", "postgres")
  db_password = ENV.fetch("DB_PASSWORD", "postgres")
  db_host = ENV.fetch("DB_HOST", "localhost")
  db_name = ENV.fetch("DB_NAME", "clear_spec")
  db_name_secondary = ENV.fetch("DB_NAME_SECONDARY", "clear_secondary_spec")
  db_port = ENV.fetch("DB_PORT", "5432")

  Clear::SQL.init("postgres://#{db_user}:#{db_password}@#{db_host}:#{db_port}/#{db_name}?retry_attempts=1&retry_delay=1&initial_pool_size=5")
  Clear::SQL.init("secondary", "postgres://#{db_user}:#{db_password}@#{db_host}:#{db_port}/#{db_name_secondary}?retry_attempts=1&retry_delay=1&initial_pool_size=5")
end

Spec.before_suite do
  {% if flag?(:quiet) %}
    ::Log.setup(level: Log::Severity::Warn)
  {% else %}
    ::Log.setup(level: Log::Severity::Debug)
  {% end %}
end

def reinit_migration_manager
  Clear::Migration::Manager.instance.reinit!
end

def temporary(&)
  exception = nil

  Clear::SQL.with_savepoint do
    begin
      yield
    rescue e
      exception = e
    end
  ensure
    Clear::SQL.rollback
  end

  raise exception if exception
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
