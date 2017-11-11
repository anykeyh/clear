require "option_parser"

module Clear::CLI
  def self.display_help_and_exit
    puts <<-HELP
    clear-cli [options] <command>

    Commands:

      Migration:
        migration status               # Show the current status of the database.
        migration up XXX               # Turn up a specific migration.
        migration down XXX             # Turn down a specific migration.
        migration set                  # Go to a specific step. Down all migration after, up all migration before.
        migrate                        # Migrate to the newest version.
        rollback                       # Revert the last migration.
        from_models                    # Generate a migration from all the models discovered. Good for projects bootstrapping !

      Helpers:
        table2model                    # Output a model based on a pg table.
        model                          # Generate a model.

      Use --help on each command to get more informations
    HELP

    exit
  end

  def self.run
    OptionParser.parse! do |opts|
      path = Dir.current

      opts.unknown_args do |args, options|
        arg = args.shift unless args.empty?

        case arg
        when "-v", "--version"
          puts Clear::VERSION
        when "-h", "--help"
          self.display_help_and_exit
        when "migration"
          Clear::CLI::Migration.run(args)
        when "migrate"
          Clear::CLI::Migration.run(["set", "--version=-1"])
        when "rollback"
          Clear::CLI::Migration.run(["set", "--version=-2", "--down-only"])
        when "from_models"
          Clear::CLI::FromModel.run(args)
        when "table2model"
          Clear::CLI::TableToModel.run(args)
        when "model"
          Clear::CLI::Model.run(args)
        else
          display_help_and_exit
        end

        exit
      end
    end
  end
end
