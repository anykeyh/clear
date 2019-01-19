# The column feature

### The column macro

Column macro follow this syntax:

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
        <p>Default: <code>false</code>
        </p>
      </td>
    </tr>
    <tr>
      <td style="text-align:left"><code>converter</code>
      </td>
      <td style="text-align:left">
        <p>Use a specific data converter between Clear and PostgreSQL to handle this
          column. See the <a href="converters.md">section about converters in few chapters</a>.</p>
        <p>Default: Use the <code>&quot;#{Type}&quot;</code> converter; primitives
          and commons type are already mapped !</p>
      </td>
    </tr>
    <tr>
      <td style="text-align:left"><code>column_name</code>
      </td>
      <td style="text-align:left">
        <p>In the case the column name is different from the field in Clear (e.g.
          the name is a reserved keyword in Crystal Lang), you may want to change
          it here.</p>
        <p>Default: <code>method_name</code>
        </p>
      </td>
    </tr>
    <tr>
      <td style="text-align:left"><code>presence</code>
      </td>
      <td style="text-align:left">
        <p>True if Clear should check presence before inserting/updating, false otherwise.</p>
        <p>Default: true unless the type is nilable.</p>
        <p>Note: Basically, if the column has a default value setup by PostgreSQL
          (like serial type), you want to setup <code>presence</code> to <code>false</code>.</p>
      </td>
    </tr>
  </tbody>
</table>### Non-presence vs Nil

Clear use a column assignation system which provide safeguard against `NilException` while keeping possibility to fetch semi-fetched model.

For example, you may want to fetch only the `first_name` and `last_name` of a `User` through the database :

```ruby
User.query.select("first_name, last_name").each do |usr|
  puts "User: #{usr.first_name} #{usr.last_name}"
end
```

But what if by mistake your code call a non fetched field ?

```ruby
User.query.select("first_name, last_name").each do |usr|
  # Will throw an exception !
  puts "User: >#{usr.id}< - #{usr.first_name} #{usr.last_name}"
end
```

In this case, Clear will throw an exception; in short, Clear handle non-presence differently than nil in the case of columns. 

#### The \[column\_name\]\_column object

For each column present, a second property exists which provide informations about the column:

```ruby
def print_user(usr)
    puts [
        "User: ",
        usr.id_column.value(nil),
        usr.first_name_column.value(nil),
        usr.last_name_column.value(nil)
    ].compact.join(" - ")
end
```

The list of functionalities for each column is as below:

<table>
  <thead>
    <tr>
      <th style="text-align:left">Name</th>
      <th style="text-align:left">Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="text-align:left"><code>xxx_column.changed?</code>
      </td>
      <td style="text-align:left">Return true|false whether the column
        <br />as changed since the database fetch</td>
    </tr>
    <tr>
      <td style="text-align:left"><code>xxx_column.has_db_default?</code>
      </td>
      <td style="text-align:left">Return true if the presence check is set to false</td>
    </tr>
    <tr>
      <td style="text-align:left"><code>xxx_column.name</code>
      </td>
      <td style="text-align:left">Return the name of the field in the database.</td>
    </tr>
    <tr>
      <td style="text-align:left"><code>xxx_column.old_value</code>
      </td>
      <td style="text-align:left">In case of change, return the previous value, before the change</td>
    </tr>
    <tr>
      <td style="text-align:left"><code>xxx_column.revert</code>
      </td>
      <td style="text-align:left">Return the column to it's initial state; changed flag is set to false
        and <code>value</code> become <code>old_value</code>
      </td>
    </tr>
    <tr>
      <td style="text-align:left"><code>xxx_column.clear</code>
      </td>
      <td style="text-align:left">The column become in non-present state (e.g. wasn't fetched)</td>
    </tr>
    <tr>
      <td style="text-align:left"><code>xxx_column.defined?</code>
      </td>
      <td style="text-align:left">Return true if the column has a value, false otherwise</td>
    </tr>
    <tr>
      <td style="text-align:left"><code>xxx_column.value</code>
      </td>
      <td style="text-align:left">
        <p>Return the column value. Raise an error if the column is in a non-present
          state.</p>
        <p>Equivalent to <code>self.xxx</code>
        </p>
      </td>
    </tr>
    <tr>
      <td style="text-align:left"><code>xxx_column.value(default)</code>
      </td>
      <td style="text-align:left">Return the current column value, OR default if the column is in a non-present
        state</td>
    </tr>
  </tbody>
</table>### Column types

Clear already map different types of column from PostgreSQL to crystal:

<table>
  <thead>
    <tr>
      <th style="text-align:center">Crystal</th>
      <th style="text-align:center">PostgreSQL</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="text-align:center">String</td>
      <td style="text-align:center">varchar, text</td>
    </tr>
    <tr>
      <td style="text-align:center">UUID</td>
      <td style="text-align:center">uuid</td>
    </tr>
    <tr>
      <td style="text-align:center">Bool</td>
      <td style="text-align:center">boolean</td>
    </tr>
    <tr>
      <td style="text-align:center">Int8</td>
      <td style="text-align:center">byte</td>
    </tr>
    <tr>
      <td style="text-align:center">Int16</td>
      <td style="text-align:center">short</td>
    </tr>
    <tr>
      <td style="text-align:center">Int32</td>
      <td style="text-align:center">int, serial</td>
    </tr>
    <tr>
      <td style="text-align:center">Int64</td>
      <td style="text-align:center">bigint, bigserial</td>
    </tr>
    <tr>
      <td style="text-align:center">Array(Type)</td>
      <td style="text-align:center">
        <p>type[]</p>
        <p>(note: type can be primitives above)</p>
      </td>
    </tr>
    <tr>
      <td style="text-align:center">JSON::Any</td>
      <td style="text-align:center">jsonb</td>
    </tr>
    <tr>
      <td style="text-align:center">Time</td>
      <td style="text-align:center">timestamp without time zone</td>
    </tr>
  </tbody>
</table>

