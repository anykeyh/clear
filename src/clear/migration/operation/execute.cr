require "./operation"

module Clear::Migration
  struct Execute < Operation
    @up : String?
    @down : String?

    def initialize(@up = nil, @down = nil)
    end

    def up
      [@up].compact
    end

    def down
      [@down].compact
    end
  end
end
