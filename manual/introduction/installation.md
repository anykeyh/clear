# Setup

## Setup: As new project

**Note**: Clear offers a CLI but still in Alpha. Documentation for building a new project with Clear + [Kemal](https://github.com/kemalcr/kemal) will be written once the feature is done. As of now, you can just follow the paragraph below.

## Setup: In existing project

In this guide we assume you know how-to setup a proper Crystal project using shards. You may want to read first a shard guide for Crystal, like [this one](https://hackernoon.com/starting-a-project-with-crystal-and-kemal-90e2647e6c3b).

### In \`shard.yml\`

Add your dependency in the dependencies list of your `shard.yml`

{% code-tabs %}
{% code-tabs-item title="/shard.yml" %}
```yaml
dependencies:
  clear:
    github: anykeyh/clear
    branch: master
```
{% endcode-tabs-item %}
{% endcode-tabs %}

Then download the library:

{% code-tabs %}
{% code-tabs-item title="terminal" %}
```text
$ shards install
```
{% endcode-tabs-item %}
{% endcode-tabs %}

### In your source code

Assuming your main entry point of your application is `src/main.cr` , you can require and initialize Clear:

{% code-tabs %}
{% code-tabs-item title="src/main.cr" %}
```ruby
# append to your require list on top:
require "clear"

# initialize a pool of database connection:
Clear::SQL.init("postgres://postgres@localhost/my_database", 
    connection_pool_size: 5)
```
{% endcode-tabs-item %}
{% endcode-tabs %}

#### Step by Step

* `require "clear"` load the source code of Clear and provide everything needed to use the library.
* `Clear::SQL.init` prepare a certain number of connection to your database. The URL is a convention used to connect to the database, and follow this schema:

```text
postgres://USER[:PASSWORD]@HOST/DATABASE[?*OPTIONS]
```

More information about the URL notation can be found [here](https://crystal-lang.org/docs/database/)

* `connection_pool_size: 5` is optional but offers the possibility to concurrent fibers to run query at the same time. It's useful if you use an event-driven server, like Kemal.

### Installation customization

You may want to install a smaller version of Clear by calling :

```ruby
require "clear/core"
```

This will add clear without the build-in CLI and without some extensions \(jsonb, bcrypt etc...\).

