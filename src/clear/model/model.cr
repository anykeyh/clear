require "../sql"
require "./collection"
require "./column"
require "./modules/**"
require "./converter/**"
require "./validation/**"

module Clear::Model
  include Clear::Model::HasColumns
  include Clear::Model::HasHooks
  include Clear::Model::HasTimestamps
  include Clear::Model::HasSaving
  include Clear::Model::HasValidation
  include Clear::Model::HasRelations
  include Clear::Model::HasScope

  getter? persisted : Bool

  # We use here included for errors purpose.
  # The overload are shown in this case, but not in the case the constructors
  # are directly defined without the included block.
  macro included
    def initialize
      @persisted = false
    end

    def initialize(h : Hash(String, ::Clear::SQL::Any), @persisted = false, fetch_columns = false )
      @attributes.merge!(h) if fetch_columns
      set(h)
    end

    def initialize(t : NamedTuple, @persisted = false)
      set(t)
    end
  end

  # For some reasons (the class "Collection" inheriting from Generic prevent working extension...
  # So the columns will be added manually
  macro included
    class_property table : Clear::SQL::Symbolic = self.name.underscore.gsub(/::/, "_").pluralize

    class Collection < Clear::Model::CollectionBase({{@type}}); end

    def self.query
      Collection.new.from(table)
    end

    def self.find(x)
      query.where { raw(pkey) == x }.first
    end

    def self.create(x : Array(NamedTuple)) : Array(self)
      x.map do |nt|
        mdl = self.new(nt)
        mdl.save
        mdl
      end
    end

    # Default primary query is "id"
    def self.pkey : String
      "id"
    end

    def self.columns
      @@columns
    end

    macro finished
      __generate_columns
    end
  end
end

require "./reflection/**"
