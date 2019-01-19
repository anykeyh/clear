## Type conversion

By default, Clear convert already some type from Postgres. However, some others
are not supported and will then return a `Slice(UInt8)`, then converted to `String`.

It's the case currently for example for `inet`

But you can convert and old theses type easily!

All you need to do is to pass to your column definition line the optional argument
`converter` with a module or class which provide the methods `to_column` and `to_db` (see example below).

### Example

```crystal
# A special type not mapped by Clear
struct InetAddress
  initialize(s : Slice(UInt8))
    # do the convertion here
  end

  #...

  module Converter
    self.to_column(x) : InetAddress?
      case x
      when Slice(UInt8)
        return InetAddress.new(x)
      when Nil
        return nil
      else
        raise "Unable to convert: #{x.class}"
    end

    self.to_db(x: InetAddress?)
      if x
        x.to_s
      else
        nil
      end
    end
  end
end

# In your model
column ip_address : InetAddress, converter: InetAddress::Converter

```
