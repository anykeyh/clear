module Clear::Migration
  struct Execute < Operation
    @up : String?
    @down : String?

    def initialize(@up = nil, @down = nil)
    end

    def up
      @up
    end

    def down
      @down
    end
  end
end
