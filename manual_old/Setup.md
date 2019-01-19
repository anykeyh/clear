# Installation

In `shards.yml`, please add theses lines:

```yaml
dependencies:
  clear:
    github: anykeyh/clear
```

Then in your code, add the requirement:

```crystal
require "clear"
```

# Initialization

Connection can be initialized by `Clear::SQL.init(uri)` method:

```crystal
Clear::SQL.init("postgres://[USER]:[PASSWORD]@[HOST]/[DATABASE]")
```

You can fine tune your connection, accessible by the `Clear::SQL.connection` object. Check the [will/crystal-pg](https://github.com/will/crystal-pg) shards documentations for more informations.

Additional parameters like `retry_attempts`, `retry_delay` etc... can be passed to the URI. Please check [the official db documentation](https://crystal-lang.org/docs/database/connection_pool.html)

By choice, Clear doesn't offers any configuration file (e.g. `database.yml`), so you need to setup your own architecture to handle different build targets.


# Logging

By default, logging of SQL output is disabled. To enable it, you need to change the logger verbosity level:

```crystal
Clear.logger.level = ::Logger::DEBUG
```