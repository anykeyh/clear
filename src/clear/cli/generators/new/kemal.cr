require "generate"

Clear::CLI::GeneratorCommand.add("new/kemal",
  "Setup a minimal application with kemal and clear") do |args|
  g = Generate::Generator.new

  g.target_directory = "."

  OptionParser.parse(args) do |opts|
    opts.on("-d", "--directory DIRECTORY", "Set directory") do |dir|
      g.target_directory = dir
    end

    opts.on("-n", "--name NAME", "Set application name") do |name|
      g["app_name"] = name
    end
  end

  g["app_name"] ||= Dir.basename(`pwd #{g.target_directory}`.chomp)
  g["app_name_underscore"] = g["app_name"].underscore

  g["git_username"] = `git config user.email`.chomp || "email@example.com"
  g["git_email"] = `git config user.name`.chomp || "Your Name"

  g.in_directory "bin" do
    g.file "appctl", Clear::CLI::Generate.ecr_to_s("./templates/kemal/bin/appctl.ecr", opts)
    g.file "clear_cli.cr", Clear::CLI::Generate.ecr_to_s("./templates/kemal/bin/clear_cli.cr.ecr", opts)
    g.file "server.cr", Clear::CLI::Generate.ecr_to_s("./templates/kemal/bin/server.cr.ecr", opts)
  end

  g.in_directory "config" do
    g.file "database.yml", Clear::CLI::Generate.ecr_to_s("./templates/kemal/config/database.yml.ecr", opts)
  end

  g.in_directory "src" do
    g.in_directory "controllers" do
      g.file "application_controller.cr", Clear::CLI::Generate.ecr_to_s("./templates/kemal/src/controllers/application_controller.ecr", opts)
      g.file "welcome_controller.cr", Clear::CLI::Generate.ecr_to_s("./templates/kemal/src/controllers/welcome_controller.ecr", opts)
    end

    g.in_directory "db" do
      g.file "init.cr", Clear::CLI::Generate.ecr_to_s("./templates/kemal/src/db/init.ecr", opts)
    end

    g.in_directory "models" do
      g.file "init.cr", Clear::CLI::Generate.ecr_to_s("./templates/kemal/src/models/application_model.ecr", opts)
    end

    g.in_directory "views" do
      g.in_directory "components" do
        g.file "footer.cr", Clear::CLI::Generate.ecr_to_s("./templates/kemal/src/views/components/footer.ecr", opts)
      end

      g.in_directory "layouts" do
        g.file "application.cr", Clear::CLI::Generate.ecr_to_s("./templates/kemal/src/views/layouts/application.ecr", opts)
      end

      g.in_directory "welcome" do
        g.file "index.cr", Clear::CLI::Generate.ecr_to_s("./templates/kemal/src/views/welcome/index.ecr", opts)
      end
    end

    g.file "app.cr", Clear::CLI::Generate.ecr_to_s("./templates/kemal/src/app.ecr", opts)
  end

  g.file ".gitignore", Clear::CLI::Generate.ecr_to_s("./templates/kemal/_gitignore.ecr", opts)
  g.file "shard.yml", Clear::CLI::Generate.ecr_to_s("./templates/kemal/shard.yml.ecr", opts)

  system("chmod +x #{g.target_directory}/bin/appctl")
  system("cd #{g.target_directory} && shards")

  puts "Clear + Kemal template is now generated. `cd #{g.target_directory} && clear-cli server` to play ! :-)"
end
