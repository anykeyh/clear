# :nodoc:
# Used to start initialization scripts like event hooking, which are binded to `finalize`
#   before the main code.
module Clear::Model::Initializer
  macro included
    macro included
      @@initialized = false

      # :nodoc:
      macro __on_init__
        class ::\\{{@type}}
          def self.__main_init__
            previous_def
            \\{{yield}}
          end

        end
      end

      # :nodoc:
      def self.__initialize_once__
        unless @@initialized
          __main_init__
          @@initialized = true
        end
      end

      __initialize_once__
    end
  end
end
