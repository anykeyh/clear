# Describing your columns

## Clear::Model\#column

Clear offers a column macro:

```ruby
column method_name : Type, [primary: bool], [converter: "any_string"], 
    [column_name: "any_string"], [presence: bool]
```

The arguments action is defined as below:

<table>
  <thead>
    <tr>
      <th style="text-align:left">Argument name</th>
      <th style="text-align:left">Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="text-align:left"><code>primary</code>
      </td>
      <td style="text-align:left">
        <p>Whether this column should be setup as primary key or not.
          <br />Only one primary key per model is permitted.
          <br />Primary key are necessary for handling relations and some features (e.g
          default sorting)</p>
        <p><b>Default</b>: <code>false</code>
        </p>
      </td>
    </tr>
    <tr>
      <td style="text-align:left"><code>converter</code>
      </td>
      <td style="text-align:left">
        <p>Use a specific data converter between Clear and PostgreSQL to handle this
          column.</p>
        <p>&lt;b&gt;&lt;/b&gt;</p>
        <p><b>Default</b>: Will lookup for the converter related to the type of the
          column; primitives and commons type are already mapped, while complex type
          and structures must be mapped manually.<b> <br /></b>See the <a href="converters.md">section about converters</a> for
          more information.</p>
      </td>
    </tr>
    <tr>
      <td style="text-align:left"><code>column_name</code>
      </td>
      <td style="text-align:left">
        <p>In the case the column name is different from the field in Clear (e.g.
          the name is a reserved keyword in Crystal Lang), you might want to change
          it here.</p>
        <p></p>
        <p><b>Default</b>: Same name between the column in PostgreSQL and the property
          in your model</p>
      </td>
    </tr>
    <tr>
      <td style="text-align:left"><code>presence</code>
      </td>
      <td style="text-align:left">
        <p>Enable of disable the presence check done on validation and insertion
          of the model in the database. When your column has a default value setup
          by PostgreSQL (like a serial type), you want to setup <code>presence</code> to <code>false</code>.</p>
        <p></p>
        <p><b>Default</b>: <code>true</code> unless the type is <code>nilable</code>.</p>
      </td>
    </tr>
  </tbody>
</table>### Non-presence vs Nil

Clear use a column assignation system which provide safeguard against `NilException` while keeping possibility to fetch semi-fetched model. For example, you may want to fetch only the `first_name` and `last_name` of a `User` through the database:

```ruby
User.query.select("first_name, last_name").each do |usr|
  puts "User: #{usr.first_name} #{usr.last_name}"
end
```

But what if by mistake your code call a non fetched field ?

```ruby
User.query.select("first_name, last_name").each do |usr|
  # This will throw an exception !
  puts "User: #{usr.id}"
end
```

| Name | Description |  |
| :--- | :--- | :--- |
| `xxx_column.changed?` | Return `true` | `false` whether the column as changed since the last database fetch |
| `xxx_column.has_db_default?` | Return `true` if the presence check is set to false |  |
| `xxx_column.name` | Return the name of the field in the database. |  |
| `xxx_column.old_value` | In case of change, return the previous value, before the change |  |
| `xxx_column.revert` | Return the column to it's initial state; changed flag is set to false and `value` become `old_value` |  |
| `xxx_column.clear` | The column become in non-present state \(e.g. wasn't fetched\) |  |
| `xxx_column.defined?` | Return `true` if the column has a value, `false` otherwise |  |
| `xxx_column.value` | Return the column value. Raise an error if the column is in a non-present state. Equivalent to `self.xxx` |  |
| `xxx_column.value(default)` | Return the current column value, OR default if the column is in a non-present state |  |

### Column types Clear already map different types of column from PostgreSQL to Crystal:

| Crystal | PostgreSQL |
| :--- | :--- |
| `String` | `text` |
| `UUID` | `uuid` |
| `Bool` | `boolean` |
| `Int8` | `byte` |
| `Int16` | `short` |
| `Int32` | `int`, `serial` |
| `Int64` | `bigint`, `bigserial` |
| `Array(Type)` | `type[]` \(_**note**: type can be of any primitives above_\) |
| `BigDecimal` | `numeric`|
| `JSON::Any` | `jsonb` |
| `Time` | `timestamp without time zone` |

#### Using BigDecimal (in Model) and Numeric (in Migrations)
`BigDecimal` ([in `.cr`](https://crystal-lang.org/api/0.35.1/BigDecimal.html)) is mapped to `Numeric` ([in `pg`](https://www.postgresql.org/docs/9.6/datatype-numeric.html)) in migration columns (i.e. declaring column data type as `"bigdecimal"` would be equal to the column being declared with type `"numeric"`, if you wish to specify precision, and scale, please use `"numeric(precision, scale)"` or `"numeric(precision)"` (with scale defaulting to 0), instead of `"bigdecimal"`)

Please take note that PostgreSQL will throw a `numeric field overflow` (and in Clear: `Clear::SQl::Error`) if you `INSERT` into the database a BigDecimal/ numeric value with the integer part (to the left of the radix point) of a size that is bigger than the precision that is specified in the numeric type that you declare. This can be seen from the following example taken from specs:

```

  class Data
    include Clear::Model

    column id : Int32, primary: true, presence: false
    column num3 : BigDecimal?
    column num4 : BigDecimal?
  end

  class ModelSpecMigration123
    include Clear::Migration

    def change(dir)
      create_table(:model_spec_data) do |t|
        t.column "num3", "numeric(9)"
        t.column "num4", "numeric(8)"
      end
    end
end

data = Data.new
big_number = BigDecimal.new(BigInt.new("-1029387192083710928371092837019283701982370918237".to_big_i), 40) # this is the same as "-102938719.2083710928371092837019283701982370918237"
```

The following case would not throw an error
```
data.num3 = big_number
data.save!
```

However this case would throw an error
```
data.num4 = big_number
data.save!
```
