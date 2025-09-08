require "generate"

class Clear::CLI::Generator
  register_sub_command migration, type: Migration, description: "Generate a new migration"

  class Migration < Admiral::Command
    include Clear::CLI::Command

    define_help description: "Generate a new migration"

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
        class_name = name.camelcase
        migration_uid = Time.local.to_unix.to_s.rjust(10, '0')

        g["migration_uid"] = migration_uid
        g["class_name"] = class_name

        migration_file = "#{migration_uid}_#{name_underscore}.cr"

        unless Dir[File.join(g.target_directory, "src/db/migrations/*_#{name_underscore}.cr")].empty?
          puts "A migration file `xxxx_#{name_underscore}.cr` already exists"
          exit 1
        end

        g.in_directory "src/db/migrations" do
          g.file(migration_file,
            Clear::CLI::Generator.ecr_to_s(
              "#{__DIR__}/../../../../templates/migration.cr.ecr", g
            )
          )
        end
      else
        puts "Please provide a name for the migration"
        exit(1)
      end
    end
  end
end
