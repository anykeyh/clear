module Clear::Model::ClassMethods
  macro included # When included into Model
    macro included # When included into final Model
      class_property table : Clear::SQL::Symbolic = self.name.underscore.gsub(/::/, "_").pluralize
      class_property pkey : String = "id"

      class Collection < Clear::Model::CollectionBase(\{{@type}}); end

      def self.query
        Collection.new.from(table)
      end

      def self.find(x)
        query.where { raw(pkey) == x }.first
      end

      def self.find!(x)
        find(x).not_nil!
      end

      def self.create : self
          mdl = self.new
          mdl.save
          mdl
      end

      def self.create! : self
          mdl = self.new
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
        mdl = self.new(x)
        mdl.save
        mdl
      end

      def self.create!(x : NamedTuple) : self
        mdl = self.new(x)
        mdl.save!
        mdl
      end

      def self.columns
        @@columns
      end

      macro finished
        __generate_columns
      end
    end
  end
end
