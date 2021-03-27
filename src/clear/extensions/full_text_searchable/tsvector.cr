class Clear::TSVector
  struct Lexem
    record Position, weight : Char, position : UInt16

    getter value : String = ""
    getter positions : Array(Position) = [] of Position

    WEIGHTS = ['A', 'B', 'C', 'D']

    def initialize(io)
      chars = [] of UInt8

      while ((c = io.read_byte.not_nil!) != 0)
        chars << c
      end

      @value = String.new(chars.to_unsafe, chars.size)

      pos_size : UInt16 = 0_u16

      pos_size |= io.read_byte.not_nil! << 8
      pos_size |= io.read_byte.not_nil! << 0

      pos_size.times do
        pos_off_and_weight : UInt16 = 0_u16

        pos_off_and_weight |= io.read_byte.not_nil! << 8
        pos_off_and_weight |= io.read_byte.not_nil! << 0

        w = WEIGHTS[(pos_off_and_weight & 0xC000) >> 14]

        @positions << Position.new(w, pos_off_and_weight & (~0xC000))
      end
    end
  end

  getter lexems : Hash(String, Lexem) = {} of String => Lexem

  def [](key : String)
    lexems[key]
  end

  def []?(key : String)
    lexems[key]?
  end

  def to_sql
    @lexems.values.join(" ") do |v|
      {
        Clear::Expression[v.value],
        v.positions.join(",") { |p| {p.position, p.weight}.join },
      }.join(":")
    end
  end

  def initialize(io)
    size : UInt32 = 0

    size |= io.read_byte.not_nil! << 24
    size |= io.read_byte.not_nil! << 16
    size |= io.read_byte.not_nil! << 8
    size |= io.read_byte.not_nil! << 0

    size.times.each do
      l = Lexem.new(io)
      @lexems[l.value] = l
    end
  end

  def self.decode(x : Slice(UInt8))
    io = IO::Memory.new(x, writeable: false)
    Clear::TSVector.new(io)
  end

  module Converter
    def self.to_column(x) : Clear::TSVector?
      case x
      when Slice # < Here bug of the crystal compiler with Slice(UInt8), do not want to compile
        Clear::TSVector.decode(x.as(Slice(UInt8)))
      when Clear::TSVector
        x
      when Nil
        nil
      else
        raise Clear::ErrorMessages.converter_error(x.class, "TSVector")
      end
    end

    def self.to_db(x : TSVector?)
      x.try &.to_sql
    end
  end
end

Clear::Model::Converter.add_converter("Clear::TSVector", Clear::TSVector::Converter)
