# Select Clause

## String substitution in SELECT

```ruby
Mode.query.select( 
  Clear::SQL.raw("CASE WHEN x=:x THEN 1 ELSE 0 END as check", x: "blabla") 
)
```
