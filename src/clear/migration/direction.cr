# The migration direction
# is a simple `up` or `down` structure, with some helpers functions
#
# This structure cannot be instancied (private constructor),
# and the directions up and down can be accessed through constants `UP` and `DOWN`
#
# ```
# def change(dir)
#   dir.up { puts "Apply some change when we commit this migration to the database" }
#   dir.down { puts "Apply some stuff when we rollback the migration." }
# end
# ```
#
# It can be used with `Clear::Migration#irreversible!` method to disallow the downgrade
# of this migration:
#
# ```
# def change(dir)
#   dir.down { irreversible! } # Any rollback will trigger an error.
# end
# ```
#
#
module Clear::Migration
  struct Direction
    UP   = Direction.new(:up)
    DOWN = Direction.new(:down)

    @dir : Symbol

    # :nodoc:
    protected def initialize(@dir)
    end

    # Run the block if the direction is up
    def up(&block)
      yield if @dir == :up
    end

    # check if the direction is up
    def up?
      @dir == :up
    end

    # Run the block if the direction is down
    def down(&block)
      yield if @dir == :down
    end

    # check if the direction is down
    def down?
      @dir == :down
    end

    # :nodoc:
    def to_s
      @dir == :up ? "Migration::Up" : "Migration::Down"
    end
  end
end
