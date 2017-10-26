class Clear::Migration::Manager
  # Used to migrate between metadata version, in case we need it.
  METADATA_VERSION = "1"

  # Access to the singleton manager.
  def self.instance
    @@instance ||= Manager.new
  end

  def initialize
    initdb
  end

  @migrations = [] of Migration
  @loaded_migrations : Set(String) = Set(String).new

  def add(x : Class(T)) forall T
    @migrations.add(x)
  end

  def apply_all!
    @migrations.each do |x|
    end
  end

  def revert(num : Int32)
  end

  private def initdb
    Clear::SQL.execute <<-SQL
      CREATE TABLE IF NOT EXISTS __clear_metadatas ( metatype text NOT NULL, value text NOT NULL );
    SQL

    Clear::SQL.execute <<-SQL
      CREATE UNIQUE INDEX IF NOT EXISTS __clear_metadatas_idx ON __clear_metadatas (metatype, value);
    SQL

    check_version
  end

  private def check_version
    begin
      version = Clear::SQL.select("value").from("__clear_metadatas").where { metatype == "version" }.scalar(String)

      if version != METADATA_VERSION
        raise "The database has been initialized with a different version of Clear."
      end
    rescue # Must have a better exception than just "no result"...
      Clear::SQL.insert_into("__clear_metadatas", {metatype: "version", value: METADATA_VERSION}).execute
    end
  end

  def fetch_database
    Clear::SQL.select("*")
              .from("__clear_metadatas")
              .where { metatype == "migration" }.to_a.map { |m|
      @loaded_migrations.add(m["value"].as(String))
    }
  end

  def print_status
  end
end
