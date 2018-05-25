module Clear::Model::HasScope
  macro included

    # A scope allow you to filter in a very human way a set of data.
    #
    # Usage:
    #
    # ```
    #  scope("admin"){ where({role: "admin"}) }
    # ```
    #
    # for example, instead of writing:
    #
    # ```
    #   User.query.where{ (role == "admin") & (active == true) }
    # ```
    #
    # You can write:
    #
    # ```
    #   User.admin.active
    # ```
    #
    # Scope can be used for other purpose than just filter (e.g. ordering),
    # but I would not recommend it.
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
