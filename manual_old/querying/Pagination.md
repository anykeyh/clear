Clear offers methods to manage pagination of your models

Simply use `paginate` method on your collection query:


### Methods used for pagination

## `paginate`

Used to start pagination mode for your models

```crystal
  users = User.query.paginate(1, per_page: 25)
```

## `per_page`

Return the number of model per page

```crystal
  users.per_page #25
```

## `current_page`

Return the current selected page.


## `total_pages`

Return the number of pages

## `previous_page`, `next_page`, `last_page?`, `first_page?`

Return the previous, next page or `nil` if current page is the first page.
Return `true` or `false` whether the current page is the first or the last.


## Example

```ecr
<div class='my-table'>
  <% @users.each do |u| %>
    <#...>
  <% end %>
  <!-- Add pagination widget -->
  <% unless @users.first_page? %>
    <a href="...?page=<%=@users.previous_page%>">Previous</a>
  <% end %>
  <% unless @users.last_page? %>
    <a href="...?page=<%=@users.next_page%>">Next</a>
    <a href="...?page=<%=@users.total_pages%>">Last</a>
  <% end %>
</div>
```


