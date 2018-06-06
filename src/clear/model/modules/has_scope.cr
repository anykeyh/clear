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
      \{% parameters = "" %}
      \{% for arg, idx in block.args %}
        \{% parameters = parameters + "*" if(block.splat_index && idx == block.splat_index) %}
        \{% parameters = parameters + "#{arg}"  %}
        \{% parameters = parameters + ", " unless (idx == block.args.size - 1)  %}
      \{% end %}
      \{% parameters = parameters.id %}

      def self.\{{name.id}}(\{{parameters}})
        query.\{{name.id}}(\{{parameters}})
      end

      class Collection < Clear::Model::CollectionBase(\{{@type}});
        def \{{name.id}}(\{{parameters}})
          \{{yield}}
        end
      end
    end
  end
end
