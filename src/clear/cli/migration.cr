class Clear::CLI::MigrationCommand < Clear::CLI::Command
  def get_help_string
    <<-HELP
    clear-cli [cli-options] migration [migration-options]

    Commands:
        status               # Show the current status of the database.
        up XXX               # Turn up a specific migration.
        down XXX             # Turn down a specific migration.
        set XXX              # Go to a specific step. Down all migration after, up all migration before.

    Other related helpers:
      table2model                        # Output a model based on a pg table.
      generate model                     # Generate a model + migration
      generate migration                 # Create an empty migration file
    HELP
  end

  def run_impl(args)
    OptionParser.parse(args) do |opts|
      direction = :both

      opts.on("--up-only", "If command need to rollback migrations, ignore them") { direction = :up }
      opts.on("--down-only", "If command need to apply migrations, ignore them") { direction = :down }
      opts.on("-h", "--help", "Print this help") { self.display_help_and_exit(0) }

      opts.unknown_args do |args, options|
        arg = args.shift
        case arg
        when "status"
          puts Clear::Migration::Manager.instance.print_status
        when "up", "down"
          if args.size == 0
            puts "`#{arg}` require a migration number"
            self.display_help_and_exit(1)
          end

          num = Int64.new(args.shift)

          if arg == "up"
            Clear::Migration::Manager.instance.up num
          else # "down"
            Clear::Migration::Manager.instance.down num
          end
        when "set"
          if args.size == 0
            puts "`set` require a migration number."
            self.display_help_and_exit(1)
          end

          num = Int64.new(args.shift)

          Clear::Migration::Manager.instance.apply_to(num, direction: direction)
        else
          self.display_help_and_exit(1)
        end
      end
    end
  end
end
