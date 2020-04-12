# Select Clause

## The Select query

Clear allows you to build Select query  

## String substitution in SELECT

```ruby
Model.query.select( 
  Clear::SQL.raw("CASE WHEN x=:x THEN 1 ELSE 0 END as check", x: "blabla") 
)
```

