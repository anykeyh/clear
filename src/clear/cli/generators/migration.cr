Clear::CLI::Generate.add_generator("migration",
  "Create a new migration") do |opts|
  g = Generate::Generator.new
  g.target_directory = "."

  timestamp = Time.now.epoch.to_s.rjust(10, '0')

  file_name = "#{timestamp}_#{opts[:name].underscore}.cr"
  opts[:class_name] = "#{opts[:name].camelcase}#{timestamp}"

  g.in_directory "src/db/migrations" do
    g.file(file_name, "./templates/migration.ecr")
  end
end
