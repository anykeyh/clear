#### Inspection

We've reimplemented `inspect` on models, to offer debugging insights:

```text
  pp post # => #<Post:0x10c5f6720
              @attributes={},
              @cache=
               #<Clear::Model::QueryCache:0x10c6e8100
                @cache={},
                @cache_activation=Set{}>,
              @content_column=
               "...",
              @errors=[],
              @id_column=38,
              @persisted=true,
              @published_column=true,
              @read_only=false,
              @title_column="Lorem ipsum torquent inceptos"*,
              @user_id_column=5>
```

In this case, the `*` means a column is changed and the object is dirty and must
be saved on the database.

#### Log SQL queries

Clear is offering SQL logging tools, with SQL syntax colorizing in your terminal.
For activation, simply setup the logger to `DEBUG` level

```
::Log.builder.bind "clear.*", Log::Severity::Debug, Log::IOBackend.new
```

Also, Clear will log all query made, and when exception will show you the last query
in your terminal.