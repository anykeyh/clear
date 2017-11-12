# The Migration command
#
# # Commands
#
module Clear::CLI::Migration
  def self.display_help_and_exit(opts)
    puts <<-HELP
    clear-cli [cli-options] migration [migration-options]

    Commands:
        status               # Show the current status of the database.
        up XXX               # Turn up a specific migration.
        down XXX             # Turn down a specific migration.
        set XXX              # Go to a specific step. Down all migration after, up all migration before.

      Helpers:
        table2model                    # Output a model based on a pg table.
        model                          # Generate a model.
    HELP

    exit
  end

  def self.run(args)
    OptionParser.parse(args) do |opts|
      direction = :both

      opts.on("--up-only", "If command need to rollback migrations, ignore them") { direction = :up }
      opts.on("--down-only", "If command need to apply migrations, ignore them") { direction = :down }
      opts.on("-h", "--help", "print this help") { self.display_help_and_exit(opts) }

      opts.unknown_args do |args, options|
        arg = args.shift
        case arg
        when "status"
          puts Clear::Migration::Manager.instance.print_status
        when "up", "down"
          if args.size == 0
            puts "please use `#{arg}` with a number to select the migration which go #{arg}"
            self.display_help_and_exit(opts)
          end

          num = Int64.new(args.shift)

          if arg == "up"
            Clear::Migration::Manager.instance.up num
          else # "down"
            Clear::Migration::Manager.instance.down num
          end
        when "set"
          if args.size == 0
            puts "please use `set` with a number to select until which migration we go."
            self.display_help_and_exit(opts)
          end

          num = Int64.new(args.shift)

          Clear::Migration::Manager.instance.apply_to(num, direction: direction)
        else
          self.display_help_and_exit(opts)
        end
      end
    end
  end
end
