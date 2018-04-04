Clear::CLI::GeneratorCommand.add("model",
  "Create a new model and the first migration") do |args|
  g = Generate::Generator.new

  g.target_directory = "."

  OptionParser.parse(args) do |opts|
    opts.on("-d", "--directory DIRECTORY", "Set directory") do |dir|
      g.target_directory = dir
    end
  end

  name = args.shift?

  if name
    name_underscore = name.underscore
    model_table = name_underscore.pluralize
    class_name = name.camelcase

    fields = args.join("|")
    migration_uid = Time.now.epoch.to_s.rjust(10, '0')

    g["model_class"] = class_name
    g["migration_uid"] = migration_uid
    g["model_table"] = model_table
    g["model_fields"] = fields

    model_file = "#{name_underscore}.cr"
    migration_file = "#{migration_uid}_create_#{name_underscore}.cr"

    pp fields

    g.in_directory "src/models" do
      g.file(model_file, Clear::CLI::GeneratorCommand.ecr_to_s("./templates/model/model.cr.ecr", g))
      g.file(migration_file, Clear::CLI::GeneratorCommand.ecr_to_s("./templates/model/migration.cr.ecr", g))
    end
  else
    puts "Please provide a name for the migration"
    exit(1)
  end
end
