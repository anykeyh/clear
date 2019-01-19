# Model extra attributes

In some case you may want to access a column which is not owned by the model itself. This can be provided by access `attributes` hash on the model.   
In this case, you should set the optional argument `fetch_columns` to `true` during the fetching:

In the example below, we want to display a the identification document `type` and `number` for each person:

```ruby
People.query.left_join("identification_documents"){ 
    peoples.id == identification_documents.person_id
}.select(
    "people.*", 
    "identification_documents.type AS doc_type",
    "identification_documents.number AS doc_number"
).each(fetch_columns: true) do |x|
    puts "Person #{x.full_name}: " +
         "#{x.attributes["doc_type"]} - #{x.attributes["doc_number"]}"
end
```

The optional parameter fetch\_columns is available in most of the methods where we fetch to one or multiple models.

{% hint style="info" %}
`fetch_columns` reduces slightly the performance of the ORM, and that's why it's set to `false` by default.
{% endhint %}

This can be combined also with aggregate functions access, like counter:

```ruby
customers = Customer.query
    .join("shippings"){ shippings.customer_id == customer.id  }
    .select("customers.*", "COUNT(shippings.*) as shipping_count")

customers.each(fetch_columns: true) do |x|
    puts "customer #{x.id} => #{x.attributes["shipping_count"]}"
end

```

