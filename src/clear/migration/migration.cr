module Clear::Migration::Helper; end

module Clear::Migration
  include Helper

  abstract def change(dir)

  def execute(x : String)
    SQL.connection.execute(x)
  end

  def apply(dir)
    change(dir)

    if dir == :up
      @operations.each(&.up)
    elsif dir == :down
      @operations.each(&.down)
    end
  end

  def included
    Migration::Manager.instance.add(self.new)
  end
end

require "./operation"
