record Clear::CLI::Generator, name : String, desc : String, callback : Array(String) -> Void

class Clear::CLI::GeneratorCommand < Clear::CLI::Command
  def get_help_string
    <<-HELP
      clear-cli [cli-options] generate [list | generator_name] (options)

      Options:
        --list # List the generators

      Available generators:
      #{generator_list_string}
    HELP
  end

  @@generators = {} of String => Clear::CLI::Generator

  def self.add(name, desc, &block : Array(String) -> Void)
    @@generators[name] = Generator.new(name, desc, block)
  end

  def self.[]?(generator)
    @@generators[name]?
  end

  def self.[](generator)
    @@generators[name]
  end

  def generator_list_string
    @generators.values.map { |v| "  #{v.name}\t#{v.desc}" }.join("\n")
  end

  def run_impl(args)
    while args.size > 0
      arg = args.shift
      case arg
      when "--list", "-l"
        puts print_generator_list
        exit 0
      else
        generator = Clear::CLI::GeneratorCommand[arg]?
        if generator
          generator.callback.call(args)
          exit 0
        else
          puts "I don't know how to generate `#{generator}`"
          exit 1
        end
      end
    end

    display_help_and_exit 1
  end
end
