require "spec"

require "../src/clear"

# Redefine the default cost to 4 (the min) to accelerate greatly the tests.
class ::Crypto::Bcrypt::Password
  DEFAULT_COST = 4
end

def initdb
  system("echo \"DROP DATABASE IF EXISTS clear_spec;\" | psql -U postgres")
  system("echo \"CREATE DATABASE clear_spec;\" | psql -U postgres")

  system("echo \"DROP DATABASE IF EXISTS clear_secondary_spec;\" | psql -U postgres")
  system("echo \"CREATE DATABASE clear_secondary_spec;\" | psql -U postgres")
  system("echo \"CREATE TABLE models_post_stats (id serial PRIMARY KEY, post_id INTEGER);\" | psql -U postgres clear_secondary_spec")

  Clear::SQL.init("postgres://postgres@localhost/clear_spec")
  Clear::SQL.init("secondary", "postgres://postgres@localhost/clear_secondary_spec")

  {% if flag?(:quiet) %}
    Clear.logger.level = ::Logger::ERROR
  {% else %}
    Clear.logger.level = ::Logger::DEBUG
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

initdb
