# Represents the "time" object of PostgreSQL
struct TimeInDay
  getter ms : UInt64 = 0

  SECOND = 1_000_000_u64
  MINUTE = 60_u64 * SECOND
  HOUR = 60_u64 * MINUTE

  def initialize(hours, minutes, seconds = 0)
    @ms = SECOND * seconds + MINUTE * minutes + HOUR * hours
  end

  def initialize(@ms)
  end

  def +(t : Time)
    t + @ms.microseconds
  end

  def -(t : Time)
    t - @ms.microseconds
  end

  def +(x : self)
    TimeInDay.new(@ms + x.ms)
  end

  def hour
    ( @ms // HOUR )
  end

  def minutes
    ( @ms % HOUR ) // MINUTE
  end

  def seconds
    (@ms % MINUTE) // SECOND
  end

  def to_tuple
    hours, left = @ms.divmod(HOUR)
    minutes, left = left.divmod(MINUTE)
    seconds = left // SECOND

    { hours, minutes, seconds }
  end

  def inspect
    "#{self.class.name}(#{self.to_s})"
  end

  def to_s(show_seconds : Bool = true)
    io = IO::Memory.new
    to_s(io)
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
    raise "Wrong format" unless str =~ /[0-9]+:[0-9]{2}(:[0-9]{2})?/

    arr = str.split(/\:/).map &.try &.to_i

    hours = arr[0]
    minutes = arr[1]
    seconds = arr[2]?

    return TimeInDay.new(hours, minutes, seconds) if seconds

    TimeInDay.new(hours, minutes)
  end
end

struct Time
  def at(hm : TimeInDay, timezone = nil) : Time
    if timezone
      if timezone.is_a?(String)
        timezone = Time::Location.load(timezone)
      end

      self.in(timezone).at_beginning_of_day + hm.ms.microseconds
    else
      at_beginning_of_day + hm.ms.microseconds
    end
  end

  def +(t : TimeInDay)
    self + t.ms.microseconds
  end

  def -(t : TimeInDay)
    self - t.ms.microseconds
  end
end

module TimeInDay::Converter
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

Clear::Model::Converter.add_converter("TimeInDay", TimeInDay::Converter)
