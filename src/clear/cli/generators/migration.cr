Clear::CLI::GeneratorCommand.add("migration",
  "Create a new migration") do |opts|
  g = Generate::Generator.new
  g.target_directory = "."

  timestamp = Time.now.epoch.to_s.rjust(10, '0')

  name = opts.shift?

  if name
    name_underscore = name.underscore
    class_name = name.camelcase

    file_name = "#{timestamp}_#{name_underscore}.cr"
    g["class_name"] = "#{class_name}#{timestamp}"

    g.in_directory "src/db/migrations" do
      g.file(file_name, "./templates/migration.ecr")
    end
  else
    puts "Please provide a name for the migration"
    exit 1
  end
end
