require "spec"

require "../src/clear"

class ::Crypto::Bcrypt::Password
  # Redefine the default cost to 4 (the minimum allowed) to accelerate greatly the tests.
  DEFAULT_COST = 4
end

def initdb
  system("echo \"DROP DATABASE IF EXISTS clear_spec;\" | psql -U postgres 2>&1 1>/dev/null")
  system("echo \"CREATE DATABASE clear_spec;\" | psql -U postgres 2>&1 1>/dev/null")

  system("echo \"DROP DATABASE IF EXISTS clear_secondary_spec;\" | psql -U postgres 2>&1 1>/dev/null")
  system("echo \"CREATE DATABASE clear_secondary_spec;\" | psql -U postgres 2>&1 1>/dev/null")
  system("echo \"CREATE TABLE models_post_stats (id serial PRIMARY KEY, post_id INTEGER);\" | psql -U postgres clear_secondary_spec 2>&1 1>/dev/null")

  Clear::SQL.init("postgres://postgres@localhost/clear_spec", connection_pool_size: 5)
  Clear::SQL.init("secondary", "postgres://postgres@localhost/clear_secondary_spec", connection_pool_size: 5)

  Log.builder.bind "clear.*",
    {% if flag?(:quiet) %} Log::Severity::Warning {% else %} Log::Severity::Debug {% end %},
    Log::IOBackend.new
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

initdb
