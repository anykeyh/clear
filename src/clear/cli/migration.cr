module Clear::CLI::Migration
  def self.display_help_and_exit(opts)
    puts <<-HELP
    clear-cli [cli-options] migration [migration-options]

    Commands:
        status               # Show the current status of the database.
        up XXX   # Turn up a specific migration.
        down XXX # Turn down a specific migration.
        set --version=xxx    # Go to a specific step. Down all migration after, up all migration before.

      Helpers:
        table2model                    # Output a model based on a pg table.
        model                          # Generate a model.
    HELP

    exit
  end

  def self.run(args)
    OptionParser.parse(args) do |opts|
      direction = :both

      version = -1
      migration = nil

      opts.on("-m", "--migration=x",
        "set to a specific version.\n" +
        "If version number is negative, it's relative to the last migration") { |x| migration = x.to_i }

      opts.on("-v", "--version=x",
        "set to a specific version.\n" +
        "If version number is negative, it's relative to the last migration") { |x| version = x.to_i }
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
            puts "please use `up` with a number to select the migration to up"
            self.display_help_and_exit(opts)
          end

          mid = Int64.new(args.shift)

          if arg == "up"
            Clear::Migration::Manager.instance.up mid
          else # "down"
            Clear::Migration::Manager.instance.down mid
          end
        else
          self.display_help_and_exit(opts)
        end
      end
    end
  end
end
