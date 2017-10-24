module Clear::Model::HasScope
  macro included
    macro scope(name, &block)
      class Collection < Clear::Model::CollectionBase(\{{@type}});
        def \{{name.id}}
          \{{yield}}
        end
      end
    end
  end
end
