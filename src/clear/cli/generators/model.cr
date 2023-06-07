require "generate"

class Clear::CLI::Generator
  register_sub_command "model", type: Model, description: "Create a new model and the first migration"

  class Model < Admiral::Command
    include Clear::CLI::Command

    define_help description: "Create a new model and the first migration"

    define_flag directory : String,
      default: ".",
      long: directory,
      short: d,
      description: "Set target directory"

    define_argument name : String

    def run_impl
      g = Generate::Generator.new

      g.target_directory = flags.directory
      name = arguments.name

      if name
        name_underscore = name.underscore
        model_table = name_underscore.pluralize
        class_name = name.camelcase

        fields = @argv.join("|")
        migration_uid = Time.local.to_unix.to_s.rjust(10, '0')

        g["model_class"] = class_name
        g["migration_uid"] = migration_uid
        g["model_table"] = model_table
        g["model_fields"] = fields

        model_file = "#{name_underscore}.cr"
        migration_file = "#{migration_uid}_create_#{name_underscore.pluralize}.cr"

        if Dir[File.join(g.target_directory, "src/db/migrations/*_create_#{name_underscore.pluralize}.cr")].any?
          puts "A migration file `xxxx__create_#{name_underscore.pluralize}.cr` already exists"
          exit 1
        end

        g.in_directory "src/models" do
          g.file(model_file, Clear::CLI::Generator.ecr_to_s("#{__DIR__}/../../../../templates/model/model.cr.ecr", g))
        end

        g.in_directory "src/db/migrations" do
          g.file(migration_file, Clear::CLI::Generator.ecr_to_s("#{__DIR__}/../../../../templates/model/migration.cr.ecr", g))
        end
      else
        puts "Please provide a name for the model"
        exit(1)
      end
    end
  end
end
