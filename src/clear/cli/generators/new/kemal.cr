require "generate"

Clear::CLI::Generate.add_generator("new/kemal",
  "Setup a minimal application with kemal and clear") do |opts|
  g = Generate::Generator.new
  g.target_directory = opts[:directory] || "."

  g["app_name"] = opts[:app_name]
  g["app_name_underscore"] = opts[:app_name].underscore
  g["git_username"] = opts[:user_name]
  g["git_email"] = opts[:email]

  g.in_directory "bin" do
    g.file "appctl", Clear::CLI.ecr_to_s("./templates/kemal/bin/appctl.ecr", opts)
    g.file "clear_cli.cr", Clear::CLI.ecr_to_s("./templates/kemal/bin/clear_cli.cr.ecr", opts)
    g.file "server.cr", Clear::CLI.ecr_to_s("./templates/kemal/bin/server.cr.ecr", opts)
  end

  g.in_directory "config" do
    g.file "database.yml", Clear::CLI.ecr_to_s("./templates/kemal/config/database.yml.ecr", opts)
  end

  g.in_directory "src" do
    g.in_directory "controllers" do
      g.file "application_controller.cr", Clear::CLI.ecr_to_s("./templates/kemal/src/controllers/application_controller.ecr", opts)
      g.file "welcome_controller.cr", Clear::CLI.ecr_to_s("./templates/kemal/src/controllers/welcome_controller.ecr", opts)
    end

    g.in_directory "db" do
      g.file "init.cr", Clear::CLI.ecr_to_s("./templates/kemal/src/db/init.ecr", opts)
    end

    g.in_directory "models" do
      g.file "init.cr", Clear::CLI.ecr_to_s("./templates/kemal/src/models/application_model.ecr", opts)
    end

    g.in_directory "views" do
      g.in_directory "components" do
        g.file "footer.cr", Clear::CLI.ecr_to_s("./templates/kemal/src/views/components/footer.ecr", opts)
      end

      g.in_directory "layouts" do
        g.file "application.cr", Clear::CLI.ecr_to_s("./templates/kemal/src/views/layouts/application.ecr", opts)
      end

      g.in_directory "welcome" do
        g.file "index.cr", Clear::CLI.ecr_to_s("./templates/kemal/src/views/welcome/index.ecr", opts)
      end
    end

    g.file "app.cr", Clear::CLI.ecr_to_s("./templates/kemal/src/app.ecr", opts)
  end

  g.file ".gitignore", Clear::CLI.ecr_to_s("./templates/kemal/_gitignore.ecr", opts)
  g.file "shard.yml", Clear::CLI.ecr_to_s("./templates/kemal/shard.yml.ecr", opts)

  system("chmod +x #{opts[:directory]}/bin/appctl")
  system("cd #{opts[:directory]} && shards")

  puts "Clear + Kemal template is now generated. `cd #{opts[:directory]} && clear-cli server` to play ! :-)"
end
