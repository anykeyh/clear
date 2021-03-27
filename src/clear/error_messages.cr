# This module list most of the runtime errors happening in Clear.
# It's an attempt to make Clear user friendly by enabling advanced resolution
# of problems when they raise.
module Clear::ErrorMessages
  extend self

  private def build_url(url)
    url.colorize.underline.to_s
  end

  def format_width(x, w = 80)
    counter = 0
    o = [] of String

    x.split(/([ \n\t])/).each do |word|
      case word
      when "\n"
        o << word
        counter = 0
      else
        counter += word.size

        if counter > w
          o << "\n"
          if word == " "
            counter = 0
          else
            o << word
            counter = word.size
          end
        else
          o << word
        end
      end
    end

    o.join
  end

  private def build_tips(ways_to_resolve)
    if ways_to_resolve.size > 0
      "Here some tips:\n\n" +
        ways_to_resolve.join("\n\n") do |l|
          l = format_width(l, 72)
          l = "  - " + l.gsub(/\n/) { |m| "#{m}    " }
        end + "\n\n"
    end
  end

  private def build_message(message)
    "#{message}\n\n"
  end

  private def build_manual(manual_pages)
    if manual_pages.size > 0
      {
        "You may want to check the manual:",
        manual_pages.join("\n") { |x|
          build_url("https://github.com/anykeyh/clear/tree/master/manual/#{x}")
        }
      }.join("\n") + "\n\n"
    end
  end

  def build_error_message(message : String, ways_to_resolve : Tuple | Array = Tuple.new, manual_pages : Tuple | Array = Tuple.new)
    {% if flag?(:release) %}
      message
    {% else %}
      format_width({
        build_message(message),
        build_tips(ways_to_resolve),
        build_manual(manual_pages),
        (
          "You may also have encountered a bug. \n" +
          "Feel free to submit an issue: \n#{build_url("https://github.com/anykeyh/clear/issues/new")}"
        ),
        "\n\nStack trace:\n",
      }.join)
    {% end %}
  end

  def migration_already_up(number)
    build_error_message \
      "Migration already up: #{number}",
      {
        "You're trying to force a migration which is already existing in your database. " +
        "You should down the migration first, then up it again.",
      },
      {
        "migration/Migration.md",
      }
  end

  def migration_already_down(number)
    build_error_message \
      "Migration already down: #{number}",
      {
        "You're trying to force a migration which is not set in your database yet. " +
        "You should up the migration first, then down it again.",
      },
      {
        "migration/Migration.md",
      }
  end

  def migration_not_found(number)
    build_error_message \
      "The migration number `#{number}` is not found.",
      {
        "Ensure your migration files are required",
        "Number of the migrations can be found in the filename, " +
        "in the classname or in the `uid` method of the migration.",
      },
      {
        "migration/Migration.md",
      }
  end

  def no_migration_yet(version)
    build_error_message \
      "No migrations are registered yet, so we cannot go to version=#{version}",
      {
        "Ensure your migration files are required",
        "Ensure you have some migration files. Captain obvious to the rescue! ;-)",
      },
      {
        "migration/Migration.md",
      }
  end

  def uid_not_found(class_name)
    build_error_message \
      "I don't know how to order the migration `#{class_name}`",
      {
        "Rename your migration class to have the migration UID at the end of the class name",
        "Rename the file where your migration stand to have the migration UID in front of the filename",
        "Override the method `uid`. Be sure the number is immutable (e.g. return constant)",
      },
      {
        "migration/Migration.md",
      }
  end

  def migration_irreversible(name = nil, operation = nil)
    op_string = operation ? "This is caused by the operation #{operation} which is irreversible." : nil
    mig_string = name ? "The migration `#{name}` is irreversible. You're trying to down a migration which is not downable, " +
                        "because the operations are one way only." : "A migration is irreversible. You're trying to down a migration which is not downable, " +
                                                                     "because the operations are one way only."

    build_error_message \
      mig_string,
      [
        op_string,
        "Build a way to revert the migration",
        "Do not revert the migration",
        "Maybe you need to manually flush the migration using Postgres. `__clear_metadatas` table stores loaded " +
        "migrations. Good luck !",
      ].compact,
      {
        "migration/Migration.md",
      }
  end

  def migration_drop_irreversible(name)
    build_error_message \
      "Cannot revert column drop, because datatype is `unknown`",
      {
        "Add the optional previous data `type` argument in the operation `drop`:" +
        "`drop_column(table, column, type)`",
      },
      {
        "migration/Migration.md",
      }
  end

  def migration_not_unique(numbers)
    build_error_message \
      "The migration manage found collision on migration number. Migrations number are: #{numbers.join(", ")}",
      {
        "It happens when migration share the same `uid`. Try to change the UID of one of your migrations",
        "By default, Clear has a `-1` migration used internally. Do not use this migration number.",
        "Migration numbers can be found in filename, classname or return of `uid` method",
      },
      {
        "migration/Migration.md",
      }
  end

  def illegal_setter_access_to_undefined_column(name)
    build_error_message \
      "You're trying to access to the column `#{name}` but it is not initialized.",
      {
        "Ensure that the column `#{name}` exists in your table",
        "If the model comes from a collection query, there was maybe a filtering on your `select` clause, " +
        "and you forgot to declare the column `#{name}`",
        "In the case of unpersisted models, please initialize by calling `#{name}=` first",
        "For validator, try `ensure_than` method, or use `#{name}_column.defined?` to avoid your validation code.",
        "Are you calling `#{name}_column.revert` somewhere before?",
        "If your model comes from JSON, please ensure the JSON source defines the column. Usage of `strict` mode will " +
        "trigger exception on JSON loading.",
      },
      {
        "model/Definition.md",
        "model/Lifecycle.md",
      }
  end

  def null_column_mapping_error(name, type)
    build_error_message \
      "Your field `#{name}` is declared as `#{type}` but `NULL` value has been found in the database.",
      {
        "In your model, declare your column `column #{name} : #{type}?` (note the `?` which allow nil value)",
        "In your database, adding `DEFAULT` value and/or `NOT NULL` constraint should disallow NULL fields " +
        "from your data.",
      },
      {
        "model/Definition.md#presence-validation",
      }
  end

  def converter_error(from, to)
    build_error_message \
      "Clear cannot convert from `#{from}` to #{to}.",
      {
        "Ensure your database column type matches the column declaration in Clear",
      },
      {"model/Definition.md"}
  end

  def lack_of_primary_key(model_name)
    build_error_message \
      "Model `#{model_name}` lacks of primary key field",
      {
        "Define a column as primary key",
        "Only one column can be primary key (no compound keys are allowed in Clear for now)",
        "You can use the helpers for primary key (see manual page)",
      },
      {"model/PrimaryKeyTweaking.md"}
  end

  def polymorphic_nil(through)
    build_error_message \
      "Impossible to instantiate polymorphic object, because the type given by the data is nil.",
      {
        "The column `#{through}` contains NULL value, but is set as storage for " +
        "the type of the polymorphic object.",
        "Try to set DEFAULT value for your column `#{through}`",
        "In case of new implementation of polymorphic system, we recommend you to update the column to the previous " +
        "Class value. Value must be equal to the fully qualified model class name in Crystal (e.g. `MyApp::MyModel`)",
      },
      {"model/Polymorphism.md"}
  end

  def polymorphic_unknown_class(class_name)
    build_error_message \
      "Impossible to instantiate a new `#{class_name}` using polymorphism.",
      {
        "Ensure the type is properly setup in your `polymorphic` helper. " +
        "Any model which can exists in your database needs to manually be setup as in the example below:\n" +
        "`polymorphic Dog, Cat, through: \"type\"`\n" +
        "In this case, if you have a `Cow` object in your database, then add it in the list of allowed polymorphic objects.",
        "Ensure the name match a fully qualified, with full path, Clear model:\n" +
        "`polymorphic ::Animal::Dog, ::Animal::Cat, through: \"type\"`\n" +
        "The column should then contains `Animal::Dog` and not `Dog`",
      },
      {
        "model/Polymorphism.md",
      }
  end

  def order_by_error_invalid_order(current_order)
    build_error_message \
      "Order by allow only ASC and DESC directions. But #{current_order} was given.",
      {
        "Ensure to use :asc, :desc symbol (or string) when constructing your query.",
        "If the code is dynamic, force the casting to one of the two value above, to avoid SQL injection.",
      },
      {
        "querying/RequestBuilding.md",
      }
  end

  def query_building_error(message)
    Clear::SQL::QueryBuildingError.new(
      build_error_message({"You're trying to construct an invalid SQL request:\n",
                           message}.join, manual_pages: {"querying/RequestBuilding.md"})
    )
  end

  def uninitialized_db_connection(connection)
    build_error_message("You're trying to access the connection #{connection} which is not initialized",
      {
        "Use `Clear::SQL.init(#{connection}: \"postgres://XXX...\" )` on startup of your application",
        "The name of the connection (#{connection}) can't be found. It may have been mistyped.",
      }, {"Setup.md", "model/MultiConnection.md"})
  end
end
