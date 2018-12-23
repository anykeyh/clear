require "./**"

module Clear::Model
  include Clear::Model::FullTextSearchable
end

# Reopen Table to add the helpers
class Clear::Migration::Table < Clear::Migration::Operation
  include Clear::Migration::FullTextSearchableTableHelpers
end

module Clear::Migration::Helper
  include Clear::Migration::FullTextSearchableHelpers
end
