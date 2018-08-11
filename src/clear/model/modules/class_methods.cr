module Clear::Model::ClassMethods
  macro included # When included into Model
    macro included # When included into final Model
      macro inherited #Polymorphism
        macro finished
        __generate_columns
        __init_default_factory
        end
      end

      macro finished
        __generate_columns
        __init_default_factory
      end


      class_property table : Clear::SQL::Symbolic = self.name.underscore.gsub(/::/, "_").pluralize
      class_property pkey : String = "id"

      class Collection < Clear::Model::CollectionBase(\{{@type}}); end

      def self.query
        Collection.new.use_connection(connection).from(table)
      end

      def self.find(x)
        query.where { raw(pkey) == x }.first
      end

      def self.find!(x)
        find(x).not_nil!
      end

      def self.build(**x : **T) forall T
        \\{% if T.size > 0 %}
          self.new(x)
        \\{% else %}
          self.new
        \\{% end %}
      end

      # Multi-args or no-arg to named tuple
      def self.create(**args) : self
        mdl = build(**args)
        mdl.save
        mdl
      end

      # Multi-args to named tuple
      def self.create!(**args) : self
        mdl = build(**args)
        mdl.save!
        mdl
      end

      def self.create(x : Array(NamedTuple)) : Array(self)
        x.map{ |elm| create(**elm) }
      end

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
