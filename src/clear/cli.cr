require "admiral"

require "./cli/command"
require "./cli/migration"
require "./cli/generator"

module Clear::CLI
  def self.run(args = nil)
    Clear::CLI::Base.run
  end

  class Base < Admiral::Command
    include Clear::CLI::Command

    define_version Clear::VERSION
    define_help

    register_sub_command migrate, type: Clear::CLI::Migration
    register_sub_command generate, type: Clear::CLI::Generator

    def run_impl
      STDOUT.puts help
    end
  end
end
