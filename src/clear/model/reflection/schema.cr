module Clear::Model::Schema
  record Column,
    type : String,
    primary : Bool,
    converter : String,
    db_column_name : String,
    crystal_variable_name : String,
    presence : Bool

  record Relation,
    name : String,
    type : String, # Type of the Relation
    nilable : Bool,
    relation_type : Symbol,     # :has_many_through | :has_many | :belongs_to | :has_one
    foreign_key : String?,      # In case of :has_many or :belongs_to
    foreign_key_type : String?, # Type of the foreign_key
    polymorphic : Bool,
    polymorphic_type_column : String?, # The column used for polymorphism. Usually foreign_key
    through : String?,                 # In case of has_many through, which relation is used to pass through
    relation : String?,                # In case of has_many through, the field used in the relation to pass through
    primary : Bool,                    # For belongs_to, whether the column is primary or not.
    presence : Bool,                   # For belongs_to, check or not the presence
    cache : Bool

  COLUMNS   = Hash(String, Hash(String, Column)).new
  RELATIONS = Hash(String, Hash(String, Relation)).new
end
