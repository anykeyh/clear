# Migration CLI

## Available Commands

There are a few commands that makes it a more enjoyable experience to your everyday usage of Clear ORM.

### Generators

The model and scaffold generators will create migrations appropriate for adding a new model. Clear ORM provides a consice DSL for defining migrations, but these can also be generated via the CLI.

```bash
Usage:
  clear generate [flags...] [arg...]

Generate code automatically

Flags:
  --help         # Displays help for the current command.
  --no-color     # Cancel color output
  --verbose, -v  # Display verbose informations during execution

Subcommands:
  migration      # Generate a new migration
  model          # Create a new model and the first migration
  new:kemal      # Create a new project with Kemal
```

### Migration

Migrations are a convenient way to alter the database schema over time in a consistent and easy way. Clear ORM provides a beautiful DSL so that you don't have to write SQL by hand, allowing your schema and changes to be database independent.

```bash
Usage:
  clear migrate [flags...] [arg...]

Manage migration state of your database

Flags:
  --help         # Displays help for the current command.
  --no-color     # Cancel color output
  --verbose, -v  # Display verbose informations during execution

Subcommands:
  down           # Downgrade your database to a specific migration version
  migrate
  rollback       # Rollback the last up migration
  seed           # Call the seeds data
  set
  status         # Return the current state of the database
  up             # Upgrade your database to a specific migration version
```

