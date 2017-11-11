module Clear::Model::HasScope
  macro included
    macro scope(name, &block)

      def self.\{{name.id}}
        query.\{{name.id}}
      end

      class Collection < Clear::Model::CollectionBase(\{{@type}});
        def \{{name.id}}
          \{{yield}}
        end
      end
    end
  end
end
