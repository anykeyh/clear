require "../sql"
require "./collection"
require "./column"
require "./modules/**"
require "./converter/**"
require "./validation/**"

module Clear::Model
  include Clear::ErrorMessages
  include Clear::Model::Connection
  include Clear::Model::HasHooks
  include Clear::Model::HasColumns
  include Clear::Model::HasTimestamps
  include Clear::Model::HasSerialPkey
  include Clear::Model::HasSaving
  include Clear::Model::HasValidation
  include Clear::Model::HasRelations
  include Clear::Model::HasScope
  include Clear::Model::ClassMethods
  include Clear::Model::HasJson
  include Clear::Model::IsPolymorphic
  include Clear::Model::Initializer

  getter cache : Clear::Model::QueryCache?

  def pkey
    raise lack_of_primary_key(self.class.name)
  end

  # We use here included for errors purpose.
  # The overload are shown in this case, but not in the case the constructors
  # are directly defined without the included block.
  macro included
    {% raise "Do NOT include Clear::Model on struct-like objects.\n" +
             "It would behave very strangely otherwise." unless @type < Reference %}
    extend Clear::Model::HasHooks::ClassMethods

    getter cache : Clear::Model::QueryCache?
    
    def initialize(@persisted = false)
    end

    def initialize(h : Hash(String, ::Clear::SQL::Any ), @cache : Clear::Model::QueryCache? = nil, @persisted = false, fetch_columns = false )
      @attributes.merge!(h) if fetch_columns
      set(h)
    end

    def initialize(t : NamedTuple, @persisted = false)
      set(t)
    end

    # :nodoc:
    # This method is useful to trigger the initializers used to build the models.
    # Without it, the events and others stuff would be fullfilled AFTER the main code has finished.
    # 
    # I wish there was another method
    def self.__main_init__
    end
  end
end

require "./reflection/**"
