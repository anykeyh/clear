require "admiral"

require "./core"
require "./cli/command"
require "./cli/migration"
require "./cli/seed"
require "./cli/generator"

module Clear
  module CLI
    @@barebone = false

    def self.run(@@barebone = true)
      if @@barebone
        Clear::CLI::Barebone.run
      else
        Clear::CLI::Base.run
      end
    end

    class Barebone < Admiral::Command
      include Clear::CLI::Command

      define_version Clear::VERSION
      define_help

      register_sub_command generate, type: Clear::CLI::Generator

      def run_impl
        STDOUT.puts help
      end
    end

    class Base < Admiral::Command
      include Clear::CLI::Command

      define_version Clear::VERSION
      define_help

      register_sub_command migrate, type: Clear::CLI::Migration
      register_sub_command generate, type: Clear::CLI::Generator
      register_sub_command seed, type: Clear::CLI::Seed

      def run_impl
        STDOUT.puts help
      end
    end
  end

  # Check for the CLI. If the CLI is not triggered, yield the block passed as parameter
  def self.with_cli(&)
    # pp ARGV
    if ARGV.size > 0 && ARGV[0] == "clear"
      ARGV.shift
      Clear::CLI.run(false)
    else
      yield
    end
  end
end
