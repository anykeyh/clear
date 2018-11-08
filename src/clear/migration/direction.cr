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
module Clear::Migration
  struct Direction
    UP   = Direction.new(true)
    DOWN = Direction.new(false)

    @dir : Bool

    # :nodoc:
    protected def initialize(@dir)
    end

    # Run the block given in parameter if the direction is a upstream
    def up(&block)
      yield if @dir
    end

    # Return true whether the migration is a upstream
    def up?
      @dir
    end

    # Run the block given in parameter if the direction is a rollback
    def down(&block)
      yield unless @dir
    end

    # Return true whether the migration is a rollback
    def down?
      !@dir
    end

    # :nodoc:
    def to_s
      @dir ? "Direction::Up" : "Direction::Down"
    end

    # :nodoc:
    def to_str
      to_s
    end
  end
end
