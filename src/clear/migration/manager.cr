require "./migration"

class Clear::Migration::Manager
  # Used to migrate between metadata version, in case we need it in the future.
  METADATA_VERSION = "1"

  # Access to the singleton manager.
  def self.instance
    @@instance ||= Manager.new
  end

  def initialize
    initdb
  end

  @migrations = [] of Migration
  @existing_migrations : Set(String) = Set(String).new

  def add(x : Class(T)) forall T
    @migrations.add(x)
  end

  def apply_all!
    list_of_migrations = @migrations.map { |x| [x.name, x] }.sort { |a, b| a.uid <=> b.uid }
    @migrations.each do |x|
      x.name
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
    load_existing_migrations
    ensure_unicity!
  end

  private def check_version
    begin
      version = Clear::SQL.select("value").from("__clear_metadatas").where(metatype: "version").scalar(String)

      if version != METADATA_VERSION
        raise "The database has been initialized with a different version of Clear.\n" +
              " (wanted: #{METADATA_VERSION}, current: #{version})"
      end
    rescue
      #
      # The shard db Must have a better exception than just "no result" in scalar fetching
      # because it breaks here the code...
      # TODO: Fixme
      Clear::SQL.insert_into("__clear_metadatas", {metatype: "version", value: METADATA_VERSION}).execute
    end
  end

  ###
  # Ensure than all loaded migrations are unique using the `Migration#uid` method
  # to discriminate
  #
  private def ensure_unicity!
    migrations = @migrations.map(&.uid)
    r = migrations - migrations.uniq
    raise "Some migrations UID are not unique and will cause problem: #{r.join(", ")}" if r.any?
  end

  def load_existing_migrations
    Clear::SQL.select("*")
              .from("__clear_metadatas")
              .where(metatype: "migration").to_a.map { |m|
      @existing_migrations.add(m["value"].as(Int32))
    }
  end

  def print_status
    @migrations.each do |m|
      active = @existing_migrations.includes?(m.uid)
      puts "[#{active ? '✓' : '✗'}] #{m.class.name} ( m.uid )"
    end
  end
end
