require "option_parser"
require "ecr"

class Clear::CLI::Generator < Admiral::Command
  include Clear::CLI::Command

  record Record, name : String, desc : String, callback : Array(String) -> Nil

  define_help description: "Generate code automatically"

  class_getter generators = {} of String => Record

  def self.add(name, desc, &block : Array(String) -> Nil)
    @@generators[name] = Record.new(name, desc, block)
  end

  def self.[]?(name)
    @@generators[name]?
  end

  def self.[](name)
    @@generators[name]
  end

  def run_impl
    puts help
  end

  macro ecr_to_s(string, opts)
    opts = {{opts}}
    io = IO::Memory.new
    ECR.embed {{string}}, io
    io.to_s
  end
end

require "./generators/**"
