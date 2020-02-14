require "./operation"

module Clear::Migration
  class Execute < Operation
    def initialize(@sql : String, @irreversible : Bool? = false)
    end

    def up : Array(String)
      [@sql]
    end

    def down : Array(String)
      irreversible! if @irreversible
      [@sql]
    end
  end
end
