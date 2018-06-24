Clear offers an expression to create complex SQL query without using so much of strings object (and thus avoid SQL injection problems !).

## Usage

You can start a query over a model using `YourModel.query`. 
Queries are objects used to build a collection and fetch the models.

Like in SQL, query allow two named `where` and `having`.

Multiple flavors of both methods exists:

```crystal
  # Using named tuple. Use equality operator.
  YourModel.query.where({id: 5}) #SELECT * FROM your_models WHERE id = 5
  # Using wildcard. Good for simple requests without 
  YourModel.query.where("id = ?", 5) #SELECT * FROM your_models WHERE id = 5
  # Using symbol referenced in string.
  YourModel.query.where("id = :id OR other_id = :id", {id: 5}) #SELECT * FROM your_models WHERE id = 5 OR other_id = 5
```

The expression engine allow you to write down your conditions without usage of any strings.

```crystal
  YourModel.query.where{ (id == 5) | (other_id == 5) } #SELECT * FROM your_models WHERE id = 5 OR other_id = 5
```

### Operators

Authorized operators are:

| Operator | Description |
|:--------:|-------------|
| `&`      |  This is the `AND` operator. Because of low priority of `&` compare to `&&`, tests must be enclosed by parenthesis. | 
| `\|`      | This is the `OR` operator. Behave like `AND` |
| `==`     | This is the equality operator. Translate as `=` in SQL. If compared with nil value, will translate to `IS NULL` |
| `!=`     | This is the not equal operator. Translate as `<>` in SQL. If compared with nil value however, will translate to `IS NOT NULL`  |
| `!`      | This is the not operator. Will translate to `NOT(expr...)` in SQL |
| `=~`     | This is the regexp operator. Will translate to `~*` if your expression is using ignore case flag, and `~` otherwise. Example: `firstname =~ /^yacine/i` will translate to `firstname ~* '^yacine'`
| `!~`     | Same as regexp operator, but translate to `!~*` and `!~` |
| `<`, `>`, `<=`, `>=` | Will translate to themselves in the query. |
| `x.in?(array_or_tuple)` | Will translate to `x IN (?)` in the query. Handle empty array, returning `FALSE` in this case ! |
| `between(x, y)` | Will translate to `BETWEEN x AND y` in the query. Usable with two value or (TODO) a range |

### Complex access

Exception from the operator above, any other methods will be written down as it in the database.

So expression engine allows you for complex access, for example in case of joins:

```crystal
MyModel.joins(...).query.where{ the_joined_models.my_model_id == my_model.id }
```

### Limitation

Setup a variable in the scope of the expression engine can lead to unexpected behavior. Let's say for example:

```crystal
id = 1
MyModel.query.where{ id == 5 } #Will fail !
```

Thankfully, Clear will report an error "The expression engine discovered a runtime-evaluable condition" to avoid you to waste your time. In this case, you should write:

```crystal
id = 1
MyModel.query.where{ raw("id") == 5 } #No more problem !
```

So, any value evaluable at runtime will be evaluated as static value:

```crystal
boolean = false
MyModel.query.where{ published == boolean } #WHERE published = 'f'
```

`raw` offers you a way to bypass anything just putting a raw text as part of an expression.

