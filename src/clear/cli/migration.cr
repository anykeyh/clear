class Clear::CLI::Migration < Admiral::Command
  define_help description: "Manage migration state of your database"

  class Status < Admiral::Command
    def run
      puts Clear::Migration::Manager.instance.print_status
    end
  end

  class Up < Admiral::Command
    define_argument migration_number : Int64, required: true
    define_help description: "Upgrade your database to a specific migration version"

    def run
      Clear::Migration::Manager.instance.up arguments.migration_number
    end
  end

  class Down < Admiral::Command
    define_argument migration_number : Int64, required: true
    define_help description: "Downgrade your database to a specific migration version"

    def run
      puts "down?"
      Clear::Migration::Manager.instance.down arguments.migration_number
    end
  end

  class Set < Admiral::Command
    define_flag direction : String, short: d, default: "both"
    define_argument migration_number : Int64, required: true

    def run
      dir_symbol = case flags.direction
                   when "up"
                     :up
                   when "down"
                     :down
                   when "both"
                     :both
                   else
                     puts "Bad argument --direction : #{flags.direction}. Must be up|down|both"
                     exit 1
                   end

      Clear::Migration::Manager.instance.apply_to(arguments.migration_number, direction: dir_symbol)
    end
  end

  register_sub_command status, type: Status
  register_sub_command up, type: Up
  register_sub_command down, type: Down
  register_sub_command set, type: Set

  def run
  end
end
