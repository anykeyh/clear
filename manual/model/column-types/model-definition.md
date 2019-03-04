# The column feature

## The column macro

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
</table>\#\#\# Non-presence vs Nil Clear use a column assignation system which provide safeguard against \`NilException\` while keeping possibility to fetch semi-fetched model. For example, you may want to fetch only the \`first\_name\` and \`last\_name\` of a \`User\` through the database : \`\`\`ruby User.query.select\("first\_name, last\_name"\).each do \|usr\| puts "User: \#{usr.first\_name} \#{usr.last\_name}" end \`\`\` But what if by mistake your code call a non fetched field ? \`\`\`ruby User.query.select\("first\_name, last\_name"\).each do \|usr\| \# Will throw an exception ! puts "User: &gt;\#{usr.id}

| Name | Description |
| :--- | :--- |


| `xxx_column.changed?` | Return true\|false whether the column as changed since the database fetch |
| :--- | :--- |


| `xxx_column.has_db_default?` | Return true if the presence check is set to false |
| :--- | :--- |


| `xxx_column.name` | Return the name of the field in the database. |
| :--- | :--- |


| `xxx_column.old_value` | In case of change, return the previous value, before the change |
| :--- | :--- |


| `xxx_column.revert` | Return the column to it's initial state; changed flag is set to false and `value` become `old_value` |
| :--- | :--- |


| `xxx_column.clear` | The column become in non-present state \(e.g. wasn't fetched\) |
| :--- | :--- |


| `xxx_column.defined?` | Return true if the column has a value, false otherwise |
| :--- | :--- |


<table>
  <thead>
    <tr>
      <th style="text-align:left"><code>xxx_column.value</code>
      </th>
      <th style="text-align:left">
        <p>Return the column value. Raise an error if the column is in a non-present
          state.</p>
        <p>Equivalent to <code>self.xxx</code>
        </p>
      </th>
    </tr>
  </thead>
  <tbody></tbody>
</table>| `xxx_column.value(default)` | Return the current column value, OR default if the column is in a non-present state |
| :--- | :--- |


\#\#\# Column types Clear already map different types of column from PostgreSQL to crystal:

<table>
  <thead>
    <tr>
      <th style="text-align:left">Crystal</th>
      <th style="text-align:left">PostgreSQL</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="text-align:left">String</td>
      <td style="text-align:left">varchar, text</td>
    </tr>
    <tr>
      <td style="text-align:left">UUID</td>
      <td style="text-align:left">uuid</td>
    </tr>
    <tr>
      <td style="text-align:left">Bool</td>
      <td style="text-align:left">boolean</td>
    </tr>
    <tr>
      <td style="text-align:left">Int8</td>
      <td style="text-align:left">byte</td>
    </tr>
    <tr>
      <td style="text-align:left">Int16</td>
      <td style="text-align:left">short</td>
    </tr>
    <tr>
      <td style="text-align:left">Int32</td>
      <td style="text-align:left">int, serial</td>
    </tr>
    <tr>
      <td style="text-align:left">Int64</td>
      <td style="text-align:left">bigint, bigserial</td>
    </tr>
    <tr>
      <td style="text-align:left">Array(Type)</td>
      <td style="text-align:left">
        <p>type[]</p>
        <p>(note: type can be primitives above)</p>
      </td>
    </tr>
    <tr>
      <td style="text-align:left">JSON::Any</td>
      <td style="text-align:left">jsonb</td>
    </tr>
    <tr>
      <td style="text-align:left">Time</td>
      <td style="text-align:left">timestamp without time zone</td>
    </tr>
  </tbody>
</table>