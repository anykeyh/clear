# Defining your model

Model definition in Clear is done by inclusion of the Clear::Model module in your class. Assuming we have this table in PostgreSQL:

```sql
CREATE TABLE articles (
   id serial NOT NULL PRIMARY KEY,
   name text NOT NULL,
   description text
);
```

The definition of this model is straight forward:

{% code title="article.cr" %}
```ruby
class Article
  include Clear::Model

  column name : String
  column description : String?

  column id : Int32, primary: true, presence: false
end
```
{% endcode %}

Cut step by step, this is what happens:

First, we include all the magic of Clear in our class:

```ruby
include Clear::Model
```

Second, we define `name` column as String. Clear will map automatically the column to the model attribute. 

```ruby
column name : String
```

Third, we define `description` . We defined `description`as `NULLABLE` in our database. To reflect this choice, we add `Nilable` `?` operator to our column.

```
column description : String?
```

Finally, we define `id` as our primary key for this model. While being declared as `NOT NULL`, the column is defined with a default value in PostgreSQL. Therefore, we tell Clear to not check value presence on save/validate by adding `presence: false` to the column definition.

```ruby
column id : Int32, primary: true, presence: false
```

You may now use your model :

```ruby
a = Article.new({name: "A superb article!" })
a.description = "This is a master piece!"
a.save!

puts "Article has been properly saved as id=#{a.id}"
```

By default, Clear will inflect the model name and use plural lower case version of the model name as table name \(here `articles`\).

You may want to override this behavior, by redefining `self.table` :

```ruby
class Model::Customer
  include Clear::Model

  self.table = "clients" #< Different from infered "model_customers" table.
  # ...
end
```

Next article is covering deeply the column definition and its subtleties.

