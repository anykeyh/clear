
module Clear::CLI::Command
  macro included
    define_flag verbose : Bool,
      default: false,
      long: verbose,
      short: v,
      description: "Display verbose informations during execution"

    define_flag no_color : Bool,
      default: false,
      description: "Cancel color output"

    def run
      Colorize.enabled = !flags.no_color

      ::Log.setup(:debug) if flags.verbose

      run_impl
    end
  end
end
