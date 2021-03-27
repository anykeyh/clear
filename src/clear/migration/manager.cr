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
  include Clear::ErrorMessages

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
  @migrations : Array(Clear::Migration) = [] of Clear::Migration
  @loaded : Bool = false

  # Return a set of uid of the current up migrations.
  @migrations_up : Set(Int64) = Set(Int64).new

  def migrations_up
    ensure_ready
    @migrations_up
  end

  protected def initialize
  end

  # :nodoc:
  def add(x : Clear::Migration)
    @migrations << x
  end

  def current_version
    ensure_ready

    if @migrations_up.any?
      @migrations_up.max
    else
      nil
    end
  end

  def max_version
    if @migrations.size > 0
      @migrations.map(&.uid).max
    else
      nil
    end
  end

  # Compute the wanted version. if the number is negative, try to get
  # the version starting by the end.
  private def compute_version(version, list_of_migrations)
    # Apply negative version
    return version if version >= 0

    raise no_migration_yet(version) if current_version.nil?

    list_of_migrations.size + version <= 0 ? 0 : list_of_migrations[version - 1].uid
  end

  def apply_to(version, direction = :both)
    ensure_ready

    list_of_migrations = @migrations.sort { |a, b| a.uid <=> b.uid }

    version = compute_version(version, list_of_migrations)

    operations = [] of {Int64, Migration::Direction}

    # We migrate to a specific point; we apply all migrations
    # not yet done to this point
    # We apply migration until requested version...
    uid_to_apply = list_of_migrations.map(&.uid).reject(&.>(version)) - @migrations_up.to_a

    uid_to_apply.each do |uid|
      operations << {uid, Migration::Direction::Up}
    end

    # Then we revert migration from requested version to now
    uid_to_apply = list_of_migrations.map(&.uid).select(&.>(version)) & @migrations_up.to_a

    uid_to_apply.each do |uid|
      operations << {uid, Migration::Direction::Down}
    end

    # We sort
    # 1/ From DOWN to UP until `version` we apply UP migration
    # 2/ Then from UP TO DOWN until `version` we apply DOWN migration
    operations.sort! do |a, b|
      if a[1].up?
        if b[1].down?
          1 # up first
        else
          # Order: a <=> b
          a[0] <=> b[0]
        end
      else # a is down migration
        if b[1].down?
          # Order: b <=> a
          b[0] <=> a[0]
        else
          0 # b is preferred on a
        end
      end
    end

    if operations.empty?
      Log.info { "Nothing to do." }
      return
    end

    Log.info { "Migrations will be applied (in this order):" }
    operations.each do |(uid, d)|
      Log.info { "#{d.up? ? "[ UP ]" : "[DOWN]"} #{uid} - #{find(uid).class.name}" }
    end

    operations.each do |(uid, d)|
      if direction == :both || direction == :up
        d.up { up(uid) }
      end

      if direction == :both || direction == :down
        d.down { down(uid) }
      end
    end
  end

  # Apply all the migrations not yet applied.
  def apply_all
    ensure_ready

    Clear::View.apply(:drop)

    list_of_migrations = @migrations.sort { |a, b| a.uid <=> b.uid }
    list_of_migrations.reject! { |x| @migrations_up.includes?(x.uid) }

    list_of_migrations.each do |migration|
      migration.apply
      @migrations_up.add(migration.uid)
    end

    Clear::View.apply(:create)
  end

  #
  # Return `true` if the migration has been commited (already applied into the database)
  # or `false` otherwise
  def commited?(m : Clear::Migration)
    @migrations_up.includes?(m.uid)
  end

  # Create if needed the metadata table
  # to save the migrations.
  def ensure_ready
    unless @loaded
      Clear::SQL.execute <<-SQL
        CREATE TABLE IF NOT EXISTS __clear_metadatas ( metatype text NOT NULL, value text NOT NULL );
      SQL

      Clear::SQL.execute <<-SQL
        CREATE UNIQUE INDEX IF NOT EXISTS __clear_metadatas_idx ON __clear_metadatas (metatype, value);
      SQL

      load_existing_migrations
      ensure_unicity!

      @loaded = true
    end
  end

  # Force reloading the migration system
  # Recheck all the current up migrations
  # and the metadata table.
  # This is useful if you access to the migration process
  # through another program, or during specs
  def reinit!
    @loaded = false
    ensure_ready
    self
  end

  # : nodoc:
  # private def check_version
  #   version = Clear::SQL.select("value").from("__clear_metadatas").where({metatype: "version"}).scalar(String)

  #   if version != METADATA_VERSION
  #     raise "The database has been initialized with a different version of Clear.\n" +
  #           " (wanted: #{METADATA_VERSION}, current: #{version})"
  #   end
  # rescue e
  #   #
  #   # The shard `db` Must have a better exception than just "no result" in scalar fetching
  #   # because it breaks here the code...
  #   # TODO: Fixme
  #   # Clear::SQL.insert_into("__clear_metadatas", {metatype: "version", value: METADATA_VERSION}).execute
  #   #
  #   # raise e
  # end

  # :nodoc:
  private def ensure_unicity!
    if @migrations.any?
      all_migrations = @migrations.map(&.uid)
      r = all_migrations - all_migrations.uniq
      raise migration_not_unique(r) unless r.empty?
    end
  end

  # Fetch all the migrations already activated on the database.
  def load_existing_migrations
    @migrations_up.clear

    Clear::SQL.select("*")
      .from("__clear_metadatas")
      .where(metatype: "migration").map { |m|
      @migrations_up.add(Int64.new(m["value"].as(String)))
    }
  end

  def refresh
    load_existing_migrations
  end

  # Fetch the migration instance with the selected number
  def find(number)
    number = Int64.new(number)
    @migrations.find(&.uid.==(number)) || raise migration_not_found(number)
  end

  # Force up a migration; throw error if the migration is already up
  def up(number : Int64) : Nil
    m = find(number)

    raise migration_already_up(number) if migrations_up.includes?(number)

    m.apply(Clear::Migration::Direction::Up)
    @migrations_up.add(m.uid)
  end

  # Force down a migration; throw error if the mgiration is already down
  def down(number : Int64) : Nil
    m = find(number)

    raise migration_already_down(number) unless migrations_up.includes?(number)

    m.apply(Clear::Migration::Direction::Down)
    @migrations_up.delete(m.uid)
  end

  # Print out the status ( up | down ) of all migrations found by the manager.
  def print_status : String
    ensure_ready

    @migrations.sort do |a, b|
      a.as(Clear::Migration).uid <=> b.as(Clear::Migration).uid
    end.join("\n") do |m|
      active = @migrations_up.includes?(m.uid)
      "[#{active ? "✓".colorize.green : "✗".colorize.red}] #{m.uid} - #{m.class.name}"
    end
  end
end
