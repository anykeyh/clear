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

def temporary(&block)
  Clear::SQL.with_savepoint do
    yield
    Clear::SQL.rollback
  end
end

initdb
