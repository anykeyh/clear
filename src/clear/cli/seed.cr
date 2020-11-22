class Clear::CLI::Seed < Admiral::Command
  include Clear::CLI::Command

  define_help description: "Seed the database with seed data"

  def run_impl
    Clear.apply_seeds
  end
end
