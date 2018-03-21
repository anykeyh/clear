# The `db` command
#
# # Commands
#
module Clear::CLI::DB
  def self.display_help_and_exit(opts)
    puts <<-HELP
    clear-cli [cli-options] db [db-command]

    Commands:
        create               # Create the database
    HELP

    exit
  end

  def self.run(args)
    OptionParser.parse(args) do |opts|
      opts.unknown_args do |args, options|
        arg = args.shift
        case arg
        when "create"
          exit
        end
      end
    end
  end
end
