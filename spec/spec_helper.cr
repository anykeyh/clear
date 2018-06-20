require "spec"

require "../src/clear"

def initdb
  system("echo \"DROP DATABASE IF EXISTS clear_spec;\" | psql -U postgres")
  system("echo \"CREATE DATABASE clear_spec;\" | psql -U postgres")

  Clear::SQL.init("postgres://postgres@localhost/clear_spec")

  {% if flag?(:quiet) %}
    Clear.logger.level = ::Logger::ERROR
  {% else %}
    Clear.logger.level = ::Logger::DEBUG
  {% end %}
end

def init_secondary_db
  system("echo \"DROP DATABASE IF EXISTS clear_secondary_spec;\" | psql -U postgres")
  system("echo \"CREATE DATABASE clear_secondary_spec;\" | psql -U postgres")
  system("echo \"CREATE TABLE models_post_stats (id serial PRIMARY KEY, post_id INTEGER);\" | psql -U postgres clear_secondary_spec")
  system("echo \"INSERT INTO models_post_stats VALUES (1, 1);\" | psql -U postgres clear_secondary_spec")

  Clear::SQL.init({
    "deafult" => "postgres://postgres@localhost/clear_spec",
    "secondary" => "postgres://postgres@localhost/clear_secondary_spec",
  })
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
