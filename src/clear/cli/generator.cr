require "ecr"

module Clear::CLI
  record Generator, name : String, desc : String, callback : Hash(Symbol, String) -> Void

  @@generators : Hash(String, Generator) = {} of String => Generator

  def self.add_generator(name, desc, &block : Hash(Symbol, String) -> Void)
    add_generator Generator.new(name, desc, block)
  end

  def self.add_generator(generator : Generator)
    @@generators[generator.name] = generator
  end

  def self.run_generator(name, options, directory : String? = nil)
    opts = {} of Symbol => String

    opts[:email] = `git config user.email`.chomp || "email@example.com"
    opts[:user_name] = `git config user.name`.chomp || "Your Name"
    opts[:app_name] = "MyApp"
    opts[:app_name_underscore] = opts[:app_name].underscore
    opts[:directory] = directory || opts[:app_name_underscore]

    @@generators[name].callback.call(opts)
  end

  macro ecr_to_s(file, opts)
    io = IO::Memory.new
    ECR.embed {{file}}, io
    io.to_s
  end
end

require "./generators/**"
