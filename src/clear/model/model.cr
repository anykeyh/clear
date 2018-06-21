require "../sql"
require "./collection"
require "./column"
require "./modules/**"
require "./converter/**"
require "./validation/**"

module Clear::Model
  include Clear::Model::Connection
  include Clear::Model::HasColumns
  include Clear::Model::HasHooks
  include Clear::Model::HasTimestamps
  include Clear::Model::HasSerialPkey
  include Clear::Model::HasSaving
  include Clear::Model::HasValidation
  include Clear::Model::HasRelations
  include Clear::Model::HasScope
  include Clear::Model::ClassMethods
  include Clear::Model::IsPolymorphic

  getter cache : Clear::Model::QueryCache?

  def pkey
    raise "Please implement primary key for `#{self.class.name}`"
  end

  # We use here included for errors purpose.
  # The overload are shown in this case, but not in the case the constructors
  # are directly defined without the included block.
  macro included
    {% raise "Do NOT include Clear::Model on struct-like objects.\n"+
      "It would behave very strangely otherwise." unless @type < Reference %}

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
  end
end

require "./reflection/**"
