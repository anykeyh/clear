# Converters

Any type from PostgreSQL can be converted using converter objects. By default, Clear converts already the main type of PostgreSQL.

However, custom type may not be supported yet. Clear offers you the possibility to add a custom converter.

## Declare a new converter

The example below with a converter for a `Color` structure shoudl be straight-forward:

```ruby
require "./base"

struct MyApp::Color
  property r : UInt8 = 0
  property g : UInt8 = 0
  property b : UInt8 = 0
  property a : UInt8 = 0

  def to_s
    # ...
  end

  def self.from_string(x : String)
    # ...
  end

  def self.from_slice(x : Slice(UInt8))
    # ...
  end
end

class MyApp::ColorConverter
  def self.to_column(x) : MyApp::Color?
    case x
    when Nil
      nil
    when Slice(UInt8)
      MyApp::Color.from_slice(x)
    when String
      MyApp::Color.from_string(x)
    else
      raise "Cannot convert from #{x.class} to MyApp::Color"
    end
  end

  def self.to_db(x : MyApp::Color?)
    x.to_s #< css style output, e.g. #12345400
  end
end

Clear::Model::Converter.add_converter("MyApp::Color", MyApp::ColorConverter)
```

Then you can use your mapped type in your model:

```ruby
class MyApp::MyModel
  include Clear::Model
  #...
  column color : Color #< Automatically get the converter
end
```

## `converter` option

Optionally, you may want to use a converter which is not related to the type itself. To do so, you can pass the converter name as optional argument in the `column` declaration:

```ruby
class MyApp::MyModel
  include Clear::Model
  #...
  column s : String, converter: "my_custom_converter"
end
```

By convention, converters which map struct and class directly are named using CamelCase, while converters which are not automatic should be named using the underscore notation.

