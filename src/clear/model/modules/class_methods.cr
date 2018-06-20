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

      # Build methods are used as factory and can
      #   be redefined in case of polymorphism
      def self.build : self
        self.new
      end

      def self.build(x : NamedTuple) : self
        self.new(x)
      end

      def self.create : self
          mdl = build
          mdl.save
          mdl
      end

      def self.create! : self
          mdl = build
          mdl.save!
          mdl
      end

      def self.create(x : Array(NamedTuple)) : Array(self)
        x.map{ |elm| create(elm) }
      end

      def self.create!(x : Array(NamedTuple)) : Array(self)
        x.map{ |elm| create!(elm) }
      end

      def self.create(x : NamedTuple) : self
        mdl = build(x)
        mdl.save
        mdl
      end

      def self.create!(x : NamedTuple) : self
        mdl = build(x)
        mdl.save!
        mdl
      end

      def self.columns
        @@columns
      end
    end
  end
end
