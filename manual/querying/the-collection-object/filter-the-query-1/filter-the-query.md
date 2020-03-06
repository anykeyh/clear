# Filter the query – The Expression Engine

Because Collection represents SQL SELECT query, they offer way to filter the query. Clear offer the Expression Engine, which is inspired by Sequel. It basically helps you to write complex filter conditions without sacrificing on code expressiveness.

## The where clause

### Filtering by value

In this example, let's assume we are looking for first\_name or last\_name equals to Richard. There's many ways to write the condition:

```ruby
# Using the expression engine
User.query.where{ (first_name == "Richard") | (last_name == "Richard") }
# Using the "?" syntax
User.query.where("first_name = ? OR last_name = ?", "Richard", "Richard")
# The tuple syntax
User.query.where("first_name = :value OR last_name = :value", {value: "Richard"})
```

For very simple queries, using tuple is the way to go:

```ruby
User.query.where(first_name: "Richard") # WHERE first_name = 'Richard'
```

For more complex querying with elegance, see below.

### Expression Engine: Operators

#### Example

```ruby
y = 1
User.query.where{ x != y } # WHERE x != 1
User.query.where{ x == nil } # WHERE x IS NULL
User.query.where{ x != nil } # WHERE x IS NOT NULL
User.query.where{ first_name =~ /richard/i } # WHERE x ~* 'richard'
User.query.where{ first_name !~ /richard/ } # WHERE x !~ 'richard'
User.query.where{ ~(users.id == 1) } # WHERE NOT( users.id = 1 )
```

{% hint style="warning" %}
In the example above, if some part of the expression are existing variable in the scope of the code execution, then the value of the variable will be taken in consideration.

Otherwise, the name will refers to a column, schema or anything related to the PostgreSQL universe.
{% endhint %}

List of permitted operators: `<, >, <=, >=, !=, ==, =~, /, *, +, -`

{% hint style="success" %}
When comparing against nil with == or != operators, the expression engine
{% endhint %}

### Expression Engine: Var, Raw

As explained above, one of the caveats of the expression engine is the variable scope reduction. Basically, whenever a part of the expression can be reduced to his value in Crystal, the Expression Engine will do it, which can lead to some surprises like in this example:

```ruby
def find_per_id(id)
    User.query.where{ id == id }
end
```

In this example, id will be reduced to the value of the variable `id` and the comparaison will fail, leading to this:

```ruby
def find_per_id(id)
    User.query.where{ true }
end
```

Thankfully, the expression engine will reject any "static code" and throw an exception at compile time in this case. The good way to do it would be to use var or raw as below:

```ruby
User.query.where{ var("id") == id } # WHERE "id" = ?
User.query.where{ raw("id") == id } # WHERE id = ?
User.query.where{ raw("users.id") == id } # WHERE users.id = ?
User.query.where{var("users", "id") == id} # WHERE "users"."id" = ?
```

{% hint style="danger" %}
`raw` can lead to SQL injection, as it pastes without safeguard the string passed as parameter. On other hand, `var` will surround each part of the expression with double quote, to escape the column name _aka PostgreSQL style_.
{% endhint %}

### Range and array and other methods

Expression engine manage natively range, array and other methods as see below.

Range:

```ruby
User.query.where{ created_at.in?(5.days.from_now .. Time.local) } # WHERE created_at > ... AND created_at < ...
```

#### Array / Tuples:

```ruby
arr = ["admin", "superuser"]
User.query.where{ users.role.in?(arr) }
# OR:
User.query.where{ users.role.in?({"admin", "superuser"}) }
```

### AND, OR methods

`AND` and `OR` operators are respectively mapped as `&` and `|` . As of now, we cannot override the operators `&&` and `||` in Crystal. Since `&` and `|` behave differently in terms of priority order, parenthesis around the condition must be provided.

