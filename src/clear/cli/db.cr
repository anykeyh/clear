class Clear::CLI::DBCommand < Clear::CLI::Command
  def get_help_string
    <<-HELP
      clear-cli [cli-options] db [db-command]

      Commands:
        create               # Create the database
    HELP
  end

  def run_impl(args)
    OptionParser.parse(args) do |opts|
      opts.unknown_args do |args, _|
        arg = args.shift
        case arg
        when "create"
          puts "TODO"
          exit
        end
      end
    end
  end
end
