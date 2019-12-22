require "./operation"

module Clear::Migration
  class Execute < Operation
    @up : String?
    @down : String?
    @irreversible : Bool

    def initialize(@up = nil, @down = nil, @irreversible = false)
    end

    def up : Array(String)
      [@up].compact
    end

    def down : Array(String)
      irreversible! if @irreversible && @down.nil?
      [@down].compact
    end
  end
end
