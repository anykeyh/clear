# Inject to Clear the new features

require "./**"

module Clear::Model
  include Clear::Model::FullTextSearchable
end

# Reopen Table to add the helpers
struct Clear::Migration::Table < Clear::Migration::Operation
  include Clear::Migration::FullTextSearchableTableHelpers
end
