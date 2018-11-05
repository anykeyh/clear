require "./operation"

module Clear::Migration
  struct Execute < Operation
    @up : String?
    @down : String?

    def initialize(@up = nil, @down = nil)
    end

    def up
      @up ? [@up] : [] of String
    end

    def down
      @down ? [@down] : [] of String
    end
  end
end
