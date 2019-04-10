# Represents the "interval" object of PostgreSQL
struct Clear::SQL::Interval
  getter microseconds : Int64 = 0
  getter days : Int32 = 0
  getter months : Int32 = 0

  def initialize(
    years = 0,
    months = 0,
    weeks = 0,
    days = 0,
    hours = 0,
    minutes = 0,
    seconds = 0,
    milliseconds = 0,
    microseconds = 0
  )
    @months = (12 * years + months).to_i32
    @days = days.to_i32
    @microseconds = (
      microseconds           +
      milliseconds *  1_000  +
      seconds *   1_000_000  +
      minutes *  60_000_000  +
      hours * 3_600_000_000
    ).to_i64
  end

  def to_db
    o = [] of String

    (o << @months.to_s       << "months") if @months != 0
    (o << @days.to_s         << "days") if @days != 0
    (o << @microseconds.to_s << "microseconds") if @microseconds != 0

    o.join(" ")
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
    Clear::SQL::Interval.new(io)
  end

  module Converter
    def self.to_column(x) : Clear::SQL::Interval?
      case x
      when Slice # < Here bug of the crystal compiler with Slice(UInt8), do not want to compile
        Clear::SQL::Interval.decode(x.as(Slice(UInt8)))
      when Clear::SQL::Interval
        x
      when Nil
        nil
      else
        raise Clear::ErrorMessages.converter_error(x.class, "Interval")
      end
    end

    def self.to_db(x : Clear::SQL::Interval?)
      if (x)
        x.to_db
      else
        nil
      end
    end
  end

end

struct Time
  def +(i : Interval)
    self + i.microseconds.microseconds + i.days.days + i.months.months
  end

  def -(t : Interval)
    self - i.microseconds.microseconds - i.days.days - i.months.months
  end
end

Clear::Model::Converter.add_converter("Clear::SQL::Interval", Clear::SQL::Interval::Converter)