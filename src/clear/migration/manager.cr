require "./migration"

#
# The migration manager is a singleton, it load all the migrations,
# check which one are `up` and `down`, and can trigger one or multiple
# downgrade / upgrade of the database.
#
# The migration system needs the creation of a table named `__clear_metadatas`
# in your database. This table will be created automatically on the first
# initialization of the Migration Manager.
#
class Clear::Migration::Manager
  # Used to migrate between metadata version, in case we need it in the future.
  METADATA_VERSION = "1"

  # To access to the manager
  # ```
  # Clear::Migration::Manager.instance
  # ```
  def self.instance
    @@instance ||= Manager.new
  end

  # Return the list of all the migrations loaded into the system.
  getter migrations : Array(Migration) = [] of Migration

  # Return a set of uid of the current up migrations.
  getter migrations_up : Set(Int32) = Set(Int32).new

  protected def initialize
    ensure_database_is_ready
  end

  # :nodoc:
  def add(x : Migration)
    @migrations << x
  end

  #
  # Apply all the migrations not yet applied.
  def apply_all
    list_of_migrations = @migrations.sort { |a, b| a.uid <=> b.uid }
    list_of_migrations.reject! { |x| @migrations_up.includes?(x) }

    list_of_migrations.each(&.apply(:up))
  end

  #
  # Revert the migration specified by this `uid`
  def revert(num : Int32) # Revert a specific migration
    m = @migrations.find(&.uid.==(num))
    raise "Cannot revert #{m}: The migration is not applied" unless committed?(m)
    m.apply(:down)
  end

  #
  # Return `true` if the migration has been commited (already applied into the database)
  # or `false` otherwise
  def committed?(m : Migration)
    @migrations_up.includes?(m)
  end

  # :nodoc:
  private def ensure_database_is_ready
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

  # : nodoc:
  private def check_version
    begin
      version = Clear::SQL.select("value").from("__clear_metadatas").where({metatype: "version"}).scalar(String)

      if version != METADATA_VERSION
        raise "The database has been initialized with a different version of Clear.\n" +
              " (wanted: #{METADATA_VERSION}, current: #{version})"
      end
    rescue
      #
      # The shard db Must have a better exception than just "no result" in scalar fetching
      # because it breaks here the code...
      # TODO: Fixme
      # Clear::SQL.insert_into("__clear_metadatas", {metatype: "version", value: METADATA_VERSION}).execute
    end
  end

  # :nodoc:
  private def ensure_unicity!
    migrations = @migrations.map(&.uid)
    r = migrations - migrations.uniq
    raise "Some migrations UID are not unique and will cause problem: #{r.join(", ")}" if r.any?
  end

  # Fetch all the migrations already activated on the database.
  def load_existing_migrations
    Clear::SQL.select("*")
              .from("__clear_metadatas")
              .where({metatype: "migration"}).to_a.map { |m|
      @migrations_up.add(m["value"].as(String).to_i)
    }
  end

  # Print out the status ( up | down ) of all migrations found by the manager.
  def print_status : String
    @migrations.sort { |a, b| a.uid <=> b.uid }.map do |m|
      active = @migrations_up.includes?(m.uid)
      "[#{active ? '✓' : '✗'}] #{m.class.name} ( m.uid )"
    end.join("\n")
  end
end
