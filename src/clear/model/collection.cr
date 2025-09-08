require "../sql/select_query"

# Model definition is made by adding the `Clear::Model` mixin in your class.
# ## Simple Model
#
# ```
# class MyModel
#   include Clear::Model
#
#   column my_column : String
# end
# ```
#
# We just created a new model, linked to your database, mapping the column `my_column` of type String (`text` in postgres).
#
# Now, you can play with your model:
#
# ```
# row = MyModel.new # create an empty row
# row.my_column = "This is a content"
# row.save! # insert the new row in the database !
# ```
#
# By convention, the table name will follow an underscore, plural version of your model: `my_models`.
# A model into a module will prepend the module name before, so `Logistic::MyModel` will check for `logistic_my_models` in your database.
# You can force a specific table name using:
#
# ```
# class MyModel
#   include Clear::Model
#   self.table = "another_table_name"
# end
# ```
#
# ## Presence validation
#
# Unlike many ORM around, Clear carry about non-nullable pattern in crystal. Meaning `column my_column : String` assume than a call to `row.my_column` will return a String.
#
# But it exists cases where the column is not yet initialized:
# - When the object is built with constructor without providing the value (See above).
# - When an object is semi-fetched through the database query. This is useful to ignore some large fields non-interesting in the body of the current operation.
#
# For example, this code will compile:
#
# ```
# row = MyModel.new # create an empty row
# puts row.my_column
# ```
#
# However, it will throw a runtime exception `You cannot access to the field 'my_column' because it never has been initialized`
#
# Same way, trying to save the object will raise an error:
#
# ```
# row.save      # Will return false
# pp row.errors # Will tell you than `my_column` presence is mandatory.
# ```
#
# Thanks to expressiveness of the Crystal language, we can handle presence validation by simply using the `Nilable` type in crystal:
#
# ```
# class MyModel
#   include Clear::Model
#
#   column my_column : String? # Now, the column can be NULL or text in postgres.
# end
# ```
#
# This time, the code above will works; in case of no value, my_column will be `nil` by default.
#
# ## Querying your code
#
# Whenever you want to fetch data from your database, you must create a new collection query:
#
# `MyModel.query #Will setup a vanilla 'SELECT * FROM my_models'`
#
# Queries are fetchable using `each`:
#
# ```
# MyModel.query.each do |model|
#   # Do something with your model here.
# end
# ```
#
# ## Refining your query
#
# A collection query offers a lot of functionalities. You can read the [API](https://anykeyh.github.io/clear/Clear/Model/CollectionBase.html) for more informations.
#
# ## Column type
#
# By default, Clear map theses columns types:
#
# - `String` => `text`
# - `Numbers` (any from 8 to 64 bits, float, double, big number, big float, big decimal) => `int, large int, numeric(arbitrary precision number) etc... (depends of your choice)`
# - `Bool` => `text or bool`
# - `Time` => `timestamp without timezone or text`
# - `JSON::Any` => `json and jsonb`
# - `Nilable` => `NULL` (treated as special !)
#
# _NOTE_: The `crystal-pg` gems map also some structures like GIS coordinates, but their implementation is not tested in Clear. Use them at your own risk. Tell me if it's working 😉
#
# If you need to map special structure, see [Mapping Your Data](Mapping) guides for more informations.
#
# ## Primary key
#
# Primary key is essential for relational mapping. Currently Clear support only one column primary key.
#
# A model without primary key can work in sort of degraded mode, throwing error in case of using some methods on them:
# - `collection#first` will be throwing error if no `order_by` has been setup
#
# To setup a primary key, you can add the modifier `primary: true` to the column:
#
# ```
# class MyModel
#   include Clear::Model
#
#   column id : Int32, primary: true, presence: false
#   column my_column : String?
# end
# ```
#
# Note the flag `presence: false` added to the column. This tells Clear than presence checking on save is not mandatory. Usually this happens if you setup a default value in postgres. In the case of our primary key `id`, we use a serial auto-increment default value.
# Therefore, saving the model without primary key will works. The id will be fetched after insertion:
#
# ```
# m = MyModel
# m.save!
# m.id # Now the id value is setup.
# ```
#
# ## Helpers
#
# Clear provides various built-in helpers to facilitate your life:
#
# ### Timestamps
#
# ```
# class MyModel
#   include Clear::Model
#   timestamps # Will map the two columns 'created_at' and 'updated_at', and map some hooks to update their values.
# end
# ```
#
# Theses fields are automatically updated whenever you call `save` methods, and works as Rails ActiveRecord.
#
# ### With Serial Pkey
#
# ```
# class MyModel
#   include Clear::Model
#   with_serial_pkey "my_primary_key"
# end
# ```
#
# Basically rewrite `column id : UInt64, primary: true, presence: false`
#
# Argument is optional (default = id)
module Clear::Model
  # `CollectionBase(T)` is the base class for collection of model.
  # Collection of model are a SQL `SELECT` query mapping & building system. They are Enumerable and are
  # `Clear::SQL::SelectBuilder` behavior; therefore, they can be used array-like and are working with low-level SQL
  # Building.
  #
  # The `CollectionBase(T)` is extended by each model. For example, generating the model `MyModel` will generate the
  # class `MyModel::Collection` which inherits from `CollectionBase(MyModel)`
  #
  # Collection are instantiated using `Model.query` method.
  class CollectionBase(T)
    include Enumerable(T)
    include Clear::SQL::SelectBuilder

    # Used for build from collection
    @tags : Hash(String, Clear::SQL::Any)

    # Redefinition of the fields,
    # because of a bug in the compiler
    # https://github.com/crystal-lang/crystal/issues/5281
    # :nodoc:
    @limit : Int64?
    @offset : Int64?
    @lock : String?
    @distinct_value : String?

    @polymorphic : Bool = false
    @polymorphic_key : String?
    @polymorphic_scope : Set(String)?

    # :nodoc:
    @cache : Clear::Model::QueryCache

    # :nodoc:
    @cached_result : Array(T)?

    # :nodoc:
    property append_operation : Proc(T, T)?
    # :nodoc:
    property unlink_operation : Proc(T, T)?

    # :nodoc:
    def initialize(
      @distinct_value = nil,
      @cte = {} of String => Clear::SQL::Query::CTE::Record,
      @columns = [] of SQL::Column,
      @forced_columns = [] of SQL::Column,
      @froms = [] of SQL::From,
      @joins = [] of SQL::Join,
      @wheres = [] of Clear::Expression::Node,
      @havings = [] of Clear::Expression::Node,
      @windows = [] of {String, String},
      @group_bys = [] of SQL::Symbolic,
      @order_bys = [] of Clear::SQL::Query::OrderBy::Record,
      @limit = nil,
      @offset = nil,
      @lock = nil,
      @before_query_triggers = [] of -> Nil,
      # collection specific parameters ---v
      @tags = {} of String => Clear::SQL::Any,
      @cache = Clear::Model::QueryCache.new,
      @cached_result = nil,
    )
    end

    def dup
      if @polymorphic
        super.flag_as_polymorphic!(@polymorphic_key.not_nil!, @polymorphic_scope.not_nil!)
      else
        super
      end
    end

    # :nodoc:
    # Setup the connection of this query to be equal to the one of the model class
    def connection_name
      T.connection
    end

    # Return the model class for this collection
    def item_class
      T
    end

    # :ditto:
    def self.item_class
      T
    end

    # :nodoc:
    # Set a query cache on this Collection. Fetching and enumerate will use the cache instead of calling the SQL.
    def cached(cache : Clear::Model::QueryCache)
      @cache = cache
      self
    end

    # :nodoc:
    def with_cached_result(r : Array(T)?)
      @cached_result = r
      self
    end

    # :nodoc:
    # Used internally to fetch the models if the collection is flagged as polymorphic
    def flag_as_polymorphic!(@polymorphic_key, scope : Enumerable(String))
      @polymorphic = true
      polymorphic_scope = @polymorphic_scope = Set(String).new
      scope.each { |x| polymorphic_scope.add(x) }

      self
    end

    # :nodoc:
    # Clear the current cache
    def clear_cached_result
      @cached_result = nil
      self
    end

    # :nodoc:
    def change!
      # In case we filter this collection, we remove the cache
      clear_cached_result
    end

    # :nodoc:
    def tags(_hash : Hash(String, Clear::SQL::Any))
      @tags.merge!(_hash)
      self
    end

    def tags
      @tags
    end

    # :nodoc:
    # redefine where with tuple as argument which add tags
    def where(**tuple)
      hash = tuple.to_h.transform_keys &.to_s

      any_hash = {} of String => Clear::SQL::Any

      # remove terms which are not real value but conditions like range or array
      hash.each { |k, v|
        any_hash[k] = v if v.is_a?(Clear::SQL::Any)
      }

      tags(any_hash)
      super(__conditions: tuple)
    end

    # def where(**tuple)
    #   tags(**tuple)
    #   where(__conditions: tuple)
    #   #super(**tuple)
    # end

    # :nodoc:
    def clear_tags
      @tags = {} of String => Clear::SQL::Any
      self
    end

    # Build the SQL, send the query then iterate through each models
    # gathered by the request.
    def each(fetch_columns = false, &block : T ->)
      cr = @cached_result

      if cr
        cr.each(&block)
      else
        o = [] of T

        if @polymorphic
          fetch(fetch_all: false) do |hash|
            type = hash[@polymorphic_key].as(String)
            o << Clear::Model::Factory.build(type, hash, persisted: true, fetch_columns: fetch_columns, cache: @cache).as(T)
          end
        else
          fetch(fetch_all: false) do |hash|
            o << Clear::Model::Factory.build(T, hash, persisted: true, fetch_columns: fetch_columns, cache: @cache)
          end
        end

        o.each(&block)
      end
    end

    # Build the SQL, send the query then build and array by applying the
    # block transformation over it.
    def map(fetch_columns = false, &block : T -> X) : Array(X) forall X
      o = [] of X
      each(fetch_columns) { |mdl| o << block.call(mdl) }
      o
    end

    # Build the SQL, send the query then iterate through each models
    # gathered by the request.
    # Use a postgres cursor to avoid memory bloating.
    # Useful to fetch millions of rows at once.
    def each_with_cursor(batch = 1000, fetch_columns = false, &block : T ->)
      cr = @cached_result

      if cr
        cr.each(&block)
      else
        if @polymorphic
          fetch_with_cursor(count: batch) do |hash|
            type = hash[@polymorphic_key].as(String)
            yield(Clear::Model::Factory.build(type, hash, persisted: true, fetch_columns: fetch_columns, cache: @cache).as(T))
          end
        else
          fetch_with_cursor(count: batch) do |hash|
            yield(Clear::Model::Factory.build(T, hash, persisted: true, fetch_columns: fetch_columns, cache: @cache))
          end
        end
      end
    end

    # Build a new collection; if the collection comes from a has_many relation
    # (e.g. `my_model.associations.build`), the foreign column which store
    # the primary key of `my_model` will be setup by default, preventing you
    # to forget it.
    def build : T
      Clear::Model::Factory.build(T, @tags, persisted: false)
    end

    # Build a new collection; if the collection comes from a has_many relation
    # (e.g. `my_model.associations.build`), the foreign column which store
    # the primary key of `my_model` will be setup by default, preventing you
    # to forget it.
    # You can pass extra parameters using a named tuple:
    # `my_model.associations.build({a_column: "value"}) `
    def build(x : NamedTuple) : T
      Clear::Model::Factory.build(T, @tags.merge(x.to_h), persisted: false)
    end

    # Check whether the query return any row.
    def any?
      cr = @cached_result

      return !cr.empty? if cr

      clear_select.select("1").limit(1).fetch do |_|
        return true
      end

      false
    end

    # Inverse of `any?`, return true if the request return no rows.
    def empty?
      !any?
    end

    # Use SQL `COUNT` over your query, and return this number as a Int64
    def count(type : X.class = Int64) forall X
      cr = @cached_result
      return X.new(cr.size) unless cr.nil?

      super(type)
    end

    # Add an item to the current collection.
    #
    # If the current collection is not originated from a `has_many` or `has_many through:` relation, calling `<<` over
    # the collection will raise a `Clear::SQL::OperationNotPermittedError`
    #
    # Returns `self` and therefore can be chained
    def <<(item : T)
      append_operation = self.append_operation

      raise "Operation not permitted on this collection." unless append_operation

      append_operation.call(item)
      @cached_result.try &.<<(item)

      self
    end

    # Alias for `Collection#<<`
    def add(item : T)
      self << item
    end

    # Unlink the model currently referenced through a relation `has_many through`
    #
    # If the current colleciton doesn't come from a `has_many through` relation,
    # this method will throw `Clear::SQL::OperationNotPermittedError`
    #
    # Returns `true` if unlinking is successful (e.g. one or more rows have been updated), or `false` otherwise
    def unlink(item : T)
      unlink_operation = self.unlink_operation

      raise "Operation not permitted on this collection." unless unlink_operation

      unlink_operation.call(item)
      @cached_result.try &.delete(item)

      self
    end

    # Create an array from the query.
    def to_a(fetch_columns = false) : Array(T)
      cr = @cached_result

      return cr if cr

      o = [] of T
      each(fetch_columns: fetch_columns) { |mdl| o << mdl }
      o
    end

    # Basically a fancy way to write `OFFSET x LIMIT 1`
    def [](off, fetch_columns = false) : T
      self[off, fetch_columns]?.not_nil!
    end

    # Basically a fancy way to write `OFFSET x LIMIT 1`
    def []?(off, fetch_columns = false) : T?
      self.offset(off).first(fetch_columns)
    end

    # Get a range of models
    def [](range : Range(Number, Number), fetch_columns = false) : Array(T)
      self.offset(range.begin).limit(range.end - range.begin).to_a(fetch_columns)
    end

    # A convenient way to write `where{ condition }.first`
    def find(fetch_columns = false, &) : T?
      x = Clear::Expression.ensure_node!(with Clear::Expression.new yield)
      where(x).first(fetch_columns)
    end

    # A convenient way to write `where({any_column: "any_value"}).first`
    def find(tuple : NamedTuple, fetch_columns = false) : T?
      where(tuple).first(fetch_columns)
    end

    # A convenient way to write `where({any_column: "any_value"}).first!`
    def find!(fetch_columns = false, &) : T
      x = Clear::Expression.ensure_node!(with Clear::Expression.new yield)
      where(x).first!(fetch_columns)
    end

    # A convenient way to write `where{ condition }.first!`
    def find!(tuple : NamedTuple, fetch_columns = false) : T
      where(tuple).first(fetch_columns).not_nil!
    end

    # Returns a model using primary key equality
    # Returns `nil` if not found.
    def find(x) : T?
      where { var(T.table, T.__pkey__) == x }.first
    end

    # Returns a model using primary key equality.
    # Raises error if the model is not found.
    def find!(x) : T
      find(x) || raise Clear::SQL::RecordNotFoundError.new
    end

    def find_or_build(**tuple) : T
      find_or_build(**tuple) { }
    end

    # Try to fetch a row. If not found, build a new object and setup
    # the fields like setup in the condition tuple.
    def find_or_build(**tuple, & : T -> Nil) : T
      where(tuple) unless tuple.size == 0
      r = first

      return r if r

      str_hash = @tags.dup
      tuple.map { |k, v| str_hash[k.to_s] = v }

      r = Clear::Model::Factory.build(T, str_hash)
      yield(r)

      r
    end

    # Try to fetch a row. If not found, build a new object and setup
    # the fields like setup in the condition tuple.
    # Just after building, save the object.
    def find_or_create(**tuple) : T
      r = find_or_build(**tuple)

      r.save!
      r
    end

    # Try to fetch a row. If not found, build a new object and setup
    # the fields like setup in the condition tuple.
    # Just after building, save the object.
    def find_or_create(**tuple, & : T -> Nil) : T
      r = find_or_build(**tuple) do |mdl|
        yield(mdl)
      end

      r.save!
      r
    end

    # Get the first row from the collection query.
    # if not found, throw an error
    def first!(fetch_columns = false) : T
      first(fetch_columns) || raise Clear::SQL::RecordNotFoundError.new
    end

    # Get the first row from the collection query.
    # if not found, return `nil`
    def first(fetch_columns = false) : T?
      clone = dup

      if clone.order_bys.empty?
        key = {Clear::SQL.escape(T.table), Clear::SQL.escape(T.__pkey__)}.join(".")
        clone.order_by(key, :asc)
      end

      clone.limit(1).fetch do |hash|
        return Clear::Model::Factory.build(T, hash, persisted: true, cache: @cache, fetch_columns: fetch_columns)
      end

      nil
    end

    # Redefinition of `join_impl` to avoid ambiguity on the column
    # name if no specific column have been selected.
    protected def join_impl(name, type, lateral, clear_expr)
      self.set_default_table_wildcard(Clear::SQL.escape(T.table))
      super(name, type, lateral, clear_expr)
    end

    # Get the last row from the collection query.
    # if not found, return `nil`
    def last(fetch_columns = false) : T?
      clone = dup

      if clone.order_bys.empty?
        key = {Clear::SQL.escape(T.table), Clear::SQL.escape(T.__pkey__)}.join(".")
        clone.order_by(key, :asc)
      end

      clone.reverse_order_by.limit(1).fetch do |hash|
        return Clear::Model::Factory.build(T, hash, persisted: true, cache: @cache, fetch_columns: fetch_columns)
      end

      nil
    end

    # Get the last row from the collection query.
    # if not found, throw an error
    def last!(fetch_columns = false) : T
      last(fetch_columns) || raise Clear::SQL::RecordNotFoundError.new
    end

    # Delete all the rows which would have been returned by this collection.
    # Is equivalent to `collection.to_delete.execute`
    def delete_all : self
      to_delete.execute
      change! # because we want to clear the caches in case we do something with the collection later
    end
  end
end
