require "option_parser"

module Clear::CLI
  def self.display_help_and_exit(exit_code = 0)
    help = <<-HELP
    clear-cli [options] <command> [...]

      Commands:

      Migration:
        migration status               # Show the current status of the database.
        migration up XXX               # Turn up a specific migration.
        migration down XXX             # Turn down a specific migration.
        migration set                  # Go to a specific step.
                                       # Down all migration after,
                                       # up all migration before.
        migrate                        # Migrate to the newest version.
        rollback                       # Revert the last migration.
        from_models                    # Generate a migration from all the
                                       # models discovered.
                                       # Good for projects bootstrapping !

      Generator:
        generate XXX                   # Generate some files

      Helpers:
        table2model                    # Output a model based on a pg table.
        model                          # Generate a model.

      Use --help on each command to get more informations
    HELP

    puts format_output(help)

    exit exit_code
  end

  def self.format_output(string)
    string.gsub(/\#[^\r\n]*\n/) do |match, str|
      match.colorize.dark_gray # comment like
    end
  end

  # Do not use the clear-cli binary but instead use the appctl
  # to compile the source of the custom project
  def self.delegate_run(args = nil)
    if args
      system("./bin/appctl", ["clear_cli"] + args) ? 0 : 1
    else
      system("./bin/appctl", ["clear_cli"]) ? 0 : 1
    end
  end

  def self.ensure_in_custom_project
    unless File.exists?("./bin/appctl")
      STDERR.puts "Your current path doesn't seems to contains a clear compatible project."
      STDERR.puts "Please run this command in a compatible project !"
      exit 1
    end
  end

  def self.run(args = nil)
    args ||= ARGV

    if File.exists?("./bin/appctl")
      exit(delegate_run(args))
    end

    OptionParser.parse(args) do |opts|
      path = Dir.current

      opts.unknown_args do |args, options|
        while args.any?
          arg = args.shift

          case arg
          when "-v", "--version"
            puts Clear::VERSION
          when "-h", "--help"
            self.display_help_and_exit 0
          when "--verbose"
            Clear.logger.level = ::Logger::DEBUG
            next
          when "g", "generate"
            Clear::CLI::GeneratorCommand.new.run(args)
          when "db"
            Clear::CLI::DBCommand.new.run(args)
          when "migration"
            ensure_in_custom_project
            Clear::CLI::MigrationCommand.new.run(args)
          when "migrate"
            ensure_in_custom_project
            Clear::CLI::MigrationCommand.new.run(["set", "#{Clear::Migration::Manager.instance.max_version}"])
          when "rollback"
            ensure_in_custom_project
            Clear::CLI::MigrationCommand.new.run(["set", "-1", "--down-only"])
          when "from_models"
            ensure_in_custom_project
            # Clear::CLI::FromModel.new.run(args)
          when "table2model"
            ensure_in_custom_project
            # Clear::CLI::TableToModel.run(args)
          when "model"
            ensure_in_custom_project
            # Clear::CLI::Model.run(args)
          else
            display_help_and_exit 1
          end

          exit 0
        end

        display_help_and_exit 0
      end
    end
  end
end

require "./cli/**"
