# Defining your model

Model definition in Clear is done by inclusion of the Clear::Model module in your class. Assuming we have this table in PostgreSQL:

```sql
CREATE TABLE articles (
   id serial NOT NULL PRIMARY KEY,
   name text NOT NULL,
   description text
);
```

The definition of this model is quite straight forward:

{% code-tabs %}
{% code-tabs-item title="article.cr" %}
```ruby
class Article
  include Clear::Model

  column name : String
  column description : String?

  column id : Int32, primary: true, presence: false
end
```
{% endcode-tabs-item %}
{% endcode-tabs %}

Cut step by step, this is what happens:

```ruby
include Clear::Model
```

First, we include all the magic in our class

```ruby
column name : String
```

Second, we define `name` column as String. Clear do the mapping automatically. You may notice the column is not nilable. It's because we said `NOT NULL` for this column in our database.

```ruby
column description : String?
```

Third, we define `description`, this time a nilable string.

```ruby
column id : Int32, primary: true, presence: false
```

Finally, we define `id` as our primary key for this model. While being declared as `NOT NULL`, the serial type offers an auto-increment default value. Therefore, we ask Clear to not check the presence of `id`.

You may now use your model :

```ruby
a = Article.new({name: "A superb article!" })
a.description = "This is a master piece!"
a.save!

puts "Article has been properly saved as id=#{a.id}"
```

By default, Clear use inflector to evaluate the name of the table from the model's name. You may want to override this behavior, by redefining `self.table` :

```ruby
class Model::Customer
  include Clear::Model

  self.table = "clients" #< Different from infered "customers" table.
  # ...
end
```

Next article is covering deeply the column definition and its subtleties.

