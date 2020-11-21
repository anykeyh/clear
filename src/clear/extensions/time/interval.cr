module Clear
  module PG
    module Interval
      module Converter
        def self.to_column(x) : ::PG::Interval?
          case x
          when ::PG::Interval
            x
          when Nil
            nil
          else
            raise Clear::ErrorMessages.converter_error(x.class, "PG::Interval")
          end
        end

        def self.to_db(x : ::PG::Interval?)
          x.try &.to_sql
        end
      end
    end
  end
end

Clear::Model::Converter.add_converter("PG::Interval", Clear::PG::Interval::Converter)
