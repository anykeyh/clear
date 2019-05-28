module Clear::Model::ClassMethods
  macro included # When included into Model
    macro included # When included into final Model
      macro inherited #Polymorphism
        macro finished
          __generate_relations__
          __generate_columns__
          __register_factory__
        end
      end

      macro finished
        __generate_relations__
        __generate_columns__
        __register_factory__
      end

      # Return the table name setup for this model.
      # By convention, the class name is by default equals to the pluralized underscored string form of the model name.
      # Example:
      #
      # ```
      #   MyModel => "my_models"
      #   Person => "people"
      #   Project::Info => "project_infos"
      # ```
      #
      # The property can be updated at initialization to a custom table name:
      #
      # ```
      #   class MyModel
      #     include Clear::Model
      #
      #     self.table = "another_table_name"
      #   end
      #   MyModel.query.to_sql # SELECT * FROM "another_table_name"
      # ```
      class_property table : Clear::SQL::Symbolic = self.name.underscore.gsub(/::/, "_").pluralize

      # Define the current schema used in PostgreSQL. The value is `nil` by default, which lead to non-specified
      #   schema during the querying, and usage of "public" by PostgreSQL.
      #
      # This property can be redefined on initialization. Example:
      #
      # ```
      #   class MyModel
      #     include Clear::Model
      #
      #     self.schema = "my_schema"
      #   end
      #   MyModel.query.to_sql # SELECT * FROM "my_schema"."my_models"
      # ```
      class_property schema : Clear::SQL::Symbolic? = nil

      # :nodoc:
      # Returns the composition of schema + table
      def self.esc_schema_table
        if s = schema
          {schema, table}.map{ |x| Clear::SQL.escape(x.to_s) }.join(".")
        else
          # Default schema
          Clear::SQL.escape(table)
        end

      end

      # Returns the name of the `pkey` field
      class_property pkey : String = "id"      # <~~ FIXME

      # :nodoc:
      # FIXME
      # @@pkey : String? = nil
      # def self.pkey
      #   pkey = @@pkey
      #   raise Clear::ErrorMessages.lack_of_primary_key(self.name) unless pkey
      #   pkey
      # end
      #
      # def self.pkey=(value)
      #   @@pkey = value
      # end

      # :doc:
      # {{@type}}::Collection
      #
      # This is the object managing a `SELECT` request.
      # A new collection is created by calling `{{@type}}.query`
      #
      # Collection are mutable and refining the SQL will mutate the collection.
      # You may want to copy the collection by calling `dup`
      #
      # See `Clear::Model::CollectionBase`
      class Collection < Clear::Model::CollectionBase(\{{@type}}); end

      # Return a new empty query `SELECT * FROM [my_model_table]`. Can be refined after that.
      def self.query
        Collection.new.use_connection(connection).from(self.esc_schema_table)
      end

      # Returns a model using primary key equality
      # Returns `nil` if not found.
      def self.find(x)
        query.where { raw(pkey) == x }.first
      end

      # Returns a model using primary key equality.
      # Raises error if the model is not found.
      def self.find!(x)
        find(x) || raise Clear::SQL::RecordNotFoundError.new
      end

      # Build a new empty model and fill the columns using the NamedTuple in argument.
      #
      # Returns the new model
      def self.build(**x : **T) forall T
        \\{% if T.size > 0 %}
          self.new(x)
        \\{% else %}
          self.new
        \\{% end %}
      end

      # Build and new model and save it. Returns the model.
      #
      # The model may not be saved due to validation failure;
      # check the returned model `errors?` and `persisted?` flags.
      def self.create(**args) : self
        mdl = build(**args)
        mdl.save
        mdl
      end

      # Build and new model and save it. Returns the model.
      #
      # Returns the newly inserted model
      # Raises an exception if validation failed during the saving process.
      def self.create!(**args) : self
        mdl = build(**args)
        mdl.save!
        mdl
      end

      def self.create!(a : Hash) : self
        mdl = self.new(a)
        mdl.save!
        mdl
      end

      def self.create(x : Hash) : self
        mdl = self.new(a)
        mdl.save
        mdl
      end

      # Multi-models creation. See `Collection#create(**args)`
      #
      # Returns the list of newly created model.
      #
      # Each model will call an `INSERT` query.
      # You may want to use `Collection#import` to insert multiple model more efficiently in one query.
      def self.create(x : Array(NamedTuple)) : Array(self)
        x.map{ |elm| create(**elm) }
      end

      # Multi-models creation. See `Collection#create!(**args)`
      #
      # Returns the list of newly created model.
      # Raises exception if any of the model has validation error.
      def self.create!(x : Array(NamedTuple)) : Array(self)
        x.map{ |elm| create!(**elm) }
      end

      def self.create(x : NamedTuple) : self
        mdl = build(**x)
        mdl.save
        mdl
      end

      def self.create!(x : NamedTuple) : self
        mdl = build(**x)
        mdl.save!
        mdl
      end

      def self.columns
        @@columns
      end
    end
  end
end
