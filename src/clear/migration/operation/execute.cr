require "./operation"

module Clear::Migration
  class Execute < Operation
    @up : String?
    @down : String?
    @irreversible : Bool

    def initialize(@up = nil, @down = nil, @irreversible = false)
    end

    def up
      if @up
        [@up]
      else
        [] of String
      end
    end

    def down
      if @down
        [@down]
      else
        irreversible! if @irreversible
        [] of String
      end
    end
  end
end
