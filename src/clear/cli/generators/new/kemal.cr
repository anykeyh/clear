require "generate"

Clear::CLI::Generator.add("new/kemal",
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

  g["app_name"] = g["app_name"]? || File.basename(g.target_directory)
  g["app_name_underscore"] = g["app_name"].underscore
  g["app_name_camelcase"] = g["app_name"].camelcase

  g["git_username"] = `git config user.email`.chomp || "email@example.com"
  g["git_email"] = `git config user.name`.chomp || "Your Name"

  g.in_directory "bin" do
    g.file "appctl", Clear::CLI::Generator.ecr_to_s("./templates/kemal/bin/appctl.ecr", g)
    g.file "clear_cli.cr", Clear::CLI::Generator.ecr_to_s("./templates/kemal/bin/clear_cli.cr.ecr", g)
    g.file "server.cr", Clear::CLI::Generator.ecr_to_s("./templates/kemal/bin/server.cr.ecr", g)
  end

  g.in_directory "config" do
    g.file "database.yml", Clear::CLI::Generator.ecr_to_s("./templates/kemal/config/database.yml.ecr", g)
  end

  g.in_directory "src" do
    g.in_directory "controllers" do
      g.file "application_controller.cr", Clear::CLI::Generator.ecr_to_s("./templates/kemal/src/controllers/application_controller.ecr", g)
      g.file "welcome_controller.cr", Clear::CLI::Generator.ecr_to_s("./templates/kemal/src/controllers/welcome_controller.ecr", g)
    end

    g.in_directory "db" do
      g.file "init.cr", Clear::CLI::Generator.ecr_to_s("./templates/kemal/src/db/init.ecr", g)
    end

    g.in_directory "models" do
      g.file "init.cr", Clear::CLI::Generator.ecr_to_s("./templates/kemal/src/models/application_model.ecr", g)
    end

    g.in_directory "views" do
      g.in_directory "components" do
        g.file "footer.cr", Clear::CLI::Generator.ecr_to_s("./templates/kemal/src/views/components/footer.ecr", g)
      end

      g.in_directory "layouts" do
        g.file "application.cr", Clear::CLI::Generator.ecr_to_s("./templates/kemal/src/views/layouts/application.ecr", g)
      end

      g.in_directory "welcome" do
        g.file "index.cr", Clear::CLI::Generator.ecr_to_s("./templates/kemal/src/views/welcome/index.ecr", g)
      end
    end

    g.file "app.cr", Clear::CLI::Generator.ecr_to_s("./templates/kemal/src/app.ecr", g)
  end

  g.file ".gitignore", Clear::CLI::Generator.ecr_to_s("./templates/kemal/_gitignore.ecr", g)
  g.file "shard.yml", Clear::CLI::Generator.ecr_to_s("./templates/kemal/shard.yml.ecr", g)

  system("chmod +x #{g.target_directory}/bin/appctl")
  system("cd #{g.target_directory} && shards")

  puts "Clear + Kemal template is now generated. `cd #{g.target_directory} && clear-cli server` to play ! :-)"
end
