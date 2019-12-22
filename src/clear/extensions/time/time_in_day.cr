# `Clear::TimeInDay` represents the "time" object of PostgreSQL
#
# It can be converted automatically from/to a `time` column.
# It offers helpers which makes it usable also as a stand alone.
#
# ## Usage example
#
# ```
#   time = Clear::TimeInDay.parse("12:33")
#   puts time.hour # 12
#   puts time.minutes # 0
#
#   Time.local.at(time) # Today at 12:33:00
#   time.to_s # 12:33:00
#   time.to_s(false) # don't show seconds => 12:33
#
#   time = time + 2.minutes #12:35
# ```
#
# As with Interval, you might wanna use it as a column (use underlying `time` type in PostgreSQL):
#
# ```crystal
# class MyModel
#   include Clear::Model
#
#   column i : Clear::TimeInDay
# end
# ```
struct Clear::TimeInDay
  getter microseconds : UInt64 = 0

  private SECOND = 1_000_000_u64
  private MINUTE = 60_u64 * SECOND
  private HOUR = 60_u64 * MINUTE

  def initialize(hours, minutes, seconds = 0)
    @microseconds = (SECOND * seconds) + (MINUTE * minutes) + (HOUR * hours)
  end

  def initialize(@microseconds : UInt64 = 0)
  end

  def +(t : Time::Span)
    Clear::TimeInDay.new(microseconds: @microseconds + t.total_nanoseconds.to_i64 // 1_000)
  end

  def -(t : Time::Span)
    Clear::TimeInDay.new(microseconds: @microseconds - t.total_nanoseconds.to_i64 // 1_000)
  end

  def +(x : self)
    TimeInDay.new(@microseconds + x.ms)
  end

  def hour
    ( @microseconds // HOUR )
  end

  def minutes
    ( @microseconds % HOUR ) // MINUTE
  end

  def seconds
    (@microseconds % MINUTE) // SECOND
  end

  def total_seconds
    @microseconds // SECOND
  end

  def to_tuple
    hours, left = @microseconds.divmod(HOUR)
    minutes, left = left.divmod(MINUTE)
    seconds = left // SECOND

    { hours, minutes, seconds }
  end

  def inspect
    "#{self.class.name}(#{self.to_s})"
  end

  def to_s(show_seconds : Bool = true)
    io = IO::Memory.new
    to_s(io, show_seconds)
    io.rewind
    io.to_s
  end

  # Return a string
  def to_s(io, show_seconds : Bool = true)
    hours, minutes, seconds = to_tuple

    if show_seconds
      io << {
        hours.to_s.rjust(2, '0'),
        minutes.to_s.rjust(2, '0'),
        seconds.to_s.rjust(2, '0'),
      }.join(':')
    else
      io << {
        hours.to_s.rjust(2, '0'),
        minutes.to_s.rjust(2, '0'),
      }.join(':')
    end
  end

  # Parse a string, of format HH:MM or HH:MM:SS
  def self.parse(str : String)
    raise "Wrong format" unless str =~ /^[0-9]+:[0-9]{2}(:[0-9]{2})?$/

    arr = str.split(/\:/).map &.try &.to_i

    hours = arr[0]
    minutes = arr[1]
    seconds = arr[2]?

    return Clear::TimeInDay.new(hours, minutes, seconds) if seconds

    Clear::TimeInDay.new(hours, minutes)
  end
end

struct Time
  def at(hm : Clear::TimeInDay, timezone = nil) : Time
    if timezone
      if timezone.is_a?(String)
        timezone = Time::Location.load(timezone)
      end

      self.in(timezone).at_beginning_of_day + hm.ms.microseconds
    else
      at_beginning_of_day + hm.ms.microseconds
    end
  end

  def +(t : Clear::TimeInDay)
    self + t.ms.microseconds
  end

  def -(t : Clear::TimeInDay)
    self - t.ms.microseconds
  end
end

module Clear::TimeInDay::Converter
  def self.to_column(x) : TimeInDay?
    case x
    when TimeInDay
      x
    when UInt64
      TimeInDay.new(x)
    when Slice
      mem = IO::Memory.new(x, writeable: false)
      TimeInDay.new(mem.read_bytes(UInt64, IO::ByteFormat::BigEndian))
    when String
      TimeInDay.parse(x)
    when Nil
      nil
    else
      raise "Cannot convert to TimeInDay from #{x.class}"
    end
  end

  def self.to_db(x : TimeInDay?)
    x ? x.to_s : nil
  end
end

Clear::Model::Converter.add_converter("Clear::TimeInDay", Clear::TimeInDay::Converter)
