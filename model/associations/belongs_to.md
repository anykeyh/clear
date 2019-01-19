# belongs\_to

_Belongs to_ represents an association where the associated object share its primary key in a column of the current object. Let's give an example:

```sql
CREATE TABLE categories (
    id bigserial NOT NULL PRIMARY KEY, 
    name text NOT NULL
)

CREATE TABLE posts (
    id bigserial NOT NULL PRIMARY KEY,
    name text NOT NULL,
    content text,
    category_id bigint NOT NULL
)
```

In this case, Post belongs to categories, as it maintain a link to the category through `category_id` column.

In clear, this relation can be written like this:

```ruby
class Post
  include Clear::Model
  
  with_serial_pkey
  
  column name : String
  column content : String?
  
  belongs_to category : Category
end

class Category
  with_serial_pkey
  
  column name : String
  
  has_many posts : Post
end
```

* Clear will take care for you of the declaration of the column `category_id`
* You may notice `has_many` in Category model. We will go further onto it in the next chapter. 

### Customizing the relation

Clear uses naming convention to infer the name of the foreign key. You may want to override this behavior by adding some parameters:

```ruby
belongs_to relation_name : RelationType, 
    foreign_key: "column_name", primary: true|false, 
    key_type: AnyType?
```

| Argument | Description | Default value |
| :---: | :--- | :---: |
| `foreign_key` | The column used by the relation | `[underscore_model_name]_id` |
| `primary` | Set to true if the foreign\_key is also the primary key of this table | `false` |
| `key_type` | The type of the column. Set to the primary key type of the relative table. | `Int64?` |
| `no_cache` | Never cache the relation \(note: planned feature\) | `false` |



