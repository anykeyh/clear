abstract class Clear::CLI::Command
  def initialize
  end

  # Run the selected command with specific arguments
  abstract def run_impl(args)
  abstract def get_help_string : String

  def run(args)
    run_impl(args)
  end

  def display_help_and_exit(exit_code = 1)
    help = get_help_string()
    puts format_output(help)
    exit exit_code
  end

  def format_output(string)
    string = string.gsub(/\#[^\r\n]*\n/) do |match|
      match.colorize.light_gray # comment like
    end

    string = string.gsub(/\`[^\`]*\`/) do |match|
      match[1..-2].colorize.mode(:bright)
    end
  end
end
