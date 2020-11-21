# Represents the "interval" object of PostgreSQL
struct Clear::Interval
  getter microseconds : Int64 = 0
  getter days : Int32 = 0
  getter months : Int32 = 0

  def initialize(span : Time::Span )
    @microseconds = span.total_nanoseconds.to_i64 // 1_000
  end

  def initialize(span : Time::MonthSpan)
    @months = span.value.to_i32
  end

  def initialize(
    years : Number = 0,
    months : Number = 0,
    weeks : Number = 0,
    days : Number = 0,
    hours : Number = 0,
    minutes : Number = 0,
    seconds : Number = 0,
    milliseconds : Number = 0,
    microseconds : Number = 0
  )
    @months = (12 * years + months).to_i32
    @days = days.to_i32
    @microseconds = (
      microseconds.to_i64        +
      milliseconds *  1_000_i64  +
      seconds *   1_000_000_i64  +
      minutes *  60_000_000_i64  +
      hours * 3_600_000_000_i64
    )
  end

  def to_sql
    o = [] of String

    (o << @months.to_s       << "months") if @months != 0
    (o << @days.to_s         << "days") if @days != 0
    (o << @microseconds.to_s << "microseconds") if @microseconds != 0

    Clear::SQL.unsafe({
      "INTERVAL",
      Clear::Expression[o.join(" ")]
    }.join(" "))
  end

  def +(i : Interval)
    Interval.new(months: self.months + i.months, day: self.days + i.days, microseconds: self.microseconds + i.microseconds)
  end

  def initialize(io : IO)
    @microseconds = io.read_bytes(Int64, IO::ByteFormat::BigEndian)
    @days = io.read_bytes(Int32, IO::ByteFormat::BigEndian)
    @months = io.read_bytes(Int32, IO::ByteFormat::BigEndian)
  end

  def self.decode(x : Slice(UInt8))
    io = IO::Memory.new(x, writeable: false)
    Clear::Interval.new(io)
  end

  module Converter
    def self.to_column(x) : Clear::Interval?
      case x
      when PG::Interval
        Clear::Interval.new(months: x.months, days: x.days, microseconds: x.microseconds)
      when Slice # < Here bug of the crystal compiler with Slice(UInt8), do not want to compile
        Clear::Interval.decode(x.as(Slice(UInt8)))
      when Clear::Interval
        x
      when Nil
        nil
      else
        raise Clear::ErrorMessages.converter_error(x.class, "Interval")
      end
    end

    def self.to_db(x : Clear::Interval?)
      x.try &.to_sql
    end
  end

end

struct Time
  def +(i : Clear::Interval)
    self + i.months.months + i.days.days + i.microseconds.microseconds
  end

  def -(i : Clear::Interval)
    self - i.months.months - i.days.days - i.microseconds.microseconds
  end
end

Clear::Model::Converter.add_converter("Clear::Interval", Clear::Interval::Converter)
