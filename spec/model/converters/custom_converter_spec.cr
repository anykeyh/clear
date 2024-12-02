struct MyApp::Color
  property r : UInt8 = 0_u8
  property g : UInt8 = 0_u8
  property b : UInt8 = 0_u8
  property a : UInt8 = 0_u8

  def to_s
    @r + @g + @b + @a
  end

  def initialize(@r, @g, @b, @a)
  end

  def self.from_string(x : String)
    raise ArgumentError.new("invalid size") if x.size != 8
    array = x.split("")
    self.new((array[0] + array[1]).to_u8, (array[2] + array[3]).to_u8, (array[4] + array[5]).to_u8, (array[6] + array[7]).to_u8)
  end

  def self.from_slice(x : Slice(UInt8))
    raise ArgumentError.new("invalid size") if x.size != 4
    self.new(x[0], x[1], x[2], x[3])
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
    x.to_s # < css style output, e.g. #12345400
  end
end

Clear::Model::Converter.add_converter("MyApp::Color", MyApp::ColorConverter)

class MyApp::MyModel
  include Clear::Model
  column color : MyApp::Color # < Automatically get the converter
end

describe "Clear::Model::Converter" do
  it "should create a new model with a field from a new converter with a new type" do
    mdl1 = MyApp::MyModel.new({color: "12345400"})
    mdl1.color.r.should eq(12)
    mdl1.color.g.should eq(34)
    mdl1.color.b.should eq(54)
    mdl1.color.a.should eq(0)

    mdl2 = MyApp::MyModel.new({color: Slice[12_u8, 34_u8, 54_u8, 0_u8]})
    mdl2.color.r.should eq(12)
    mdl2.color.g.should eq(34)
    mdl2.color.b.should eq(54)
    mdl2.color.a.should eq(0)
  end
end
