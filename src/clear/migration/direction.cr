module Clear::Migration
  struct Direction
    @dir : Symbol

    def initialize(@dir)
    end

    def up(&block)
      yield if @dir == :up
    end

    def up?
      @dir == :up
    end

    def down(&block)
      yield if @dir == :down
    end

    def down?
      @dir == :down
    end
  end
end
