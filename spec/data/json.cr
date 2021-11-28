require "../spec_helper"

describe "json core extensions" do
  describe Char do
    it "return proper json" do
      {
        char: 'a'
      }.to_json.should eq(%({"char":"a"}))
    end
  end

  describe PG::Interval do
    it "returns proper json" do
      {
        int: PG::Interval.new(1,2,3)
      }.to_json.should eq(%({"int":{"microseconds":1,"days":2,"months":3}}))
    end
  end

  describe PG::Geo::Box do
    it "returns proper json" do
      {
        box: PG::Geo::Box.new(1,2,3,4)
      }.to_json.should eq(%({"box":{"x1":1.0,"y1":2.0,"x2":3.0,"y2":4.0}}))
    end
  end

  describe PG::Geo::LineSegment do
    it "returns proper json" do
      {
        box: PG::Geo::LineSegment.new(1,2,3,4)
      }.to_json.should eq(%({"box":{"x1":1.0,"y1":2.0,"x2":3.0,"y2":4.0}}))
    end
  end

  describe PG::Geo::Point do
    it "returns proper json" do
      {
        p: PG::Geo::Point.new(1,2)
      }.to_json.should eq(%({"p":{"x":1.0,"y":2.0}}))
    end
  end

  describe PG::Geo::Line do
    it "returns proper json" do
      {
        l: PG::Geo::Line.new(1,2,3)
      }.to_json.should eq(%({"l":{"a":1.0,"b":2.0,"c":3.0}}))
    end
  end

  describe PG::Geo::Circle do
    it "returns proper json" do
      {
        c: PG::Geo::Circle.new(1,2,3)
      }.to_json.should eq(%({"c":{"x":1.0,"y":2.0,"radius":3.0}}))
    end
  end

  describe PG::Geo::Path do
    it "returns proper json" do
      {
        p: PG::Geo::Path.new([
          PG::Geo::Point.new(1,2),
          PG::Geo::Point.new(3,4),
          PG::Geo::Point.new(5,6),
        ], false)
      }.to_json.should eq(%({"p":{"points":[{"x":1.0,"y":2.0},{"x":3.0,"y":4.0},{"x":5.0,"y":6.0}],"closed":false}}))
    end
  end

  describe PG::Geo::Polygon do
    it "returns proper json" do
      {
        p: PG::Geo::Polygon.new([
          PG::Geo::Point.new(1,2),
          PG::Geo::Point.new(3,4),
          PG::Geo::Point.new(5,6),
        ])
      }.to_json.should eq(%({"p":[{"x":1.0,"y":2.0},{"x":3.0,"y":4.0},{"x":5.0,"y":6.0}]}))
    end
  end

  describe Slice do
    it "returns proper json" do
      {
        s: "Helloworld".to_slice
      }.to_json.should eq(%({"s":"Qnl0ZXNbNzIsIDEwMSwgMTA4LCAxMDgsIDExMSwgMTE5LCAxMTEsIDExNCwgMTA4LCAxMDBd"}))
    end
  end

  describe PG::Numeric do
    it "returns proper json" do
      {
        n: PG::Numeric.new(10_i16, 10_i16, 0x4000, 10_i16, [1_i16,2_i16,3_i16,4_i16])
      }.to_json.should eq(%({"n":"-10002000300040000000000000000000000000000.0000000000"}))
    end
  end

  describe BigDecimal do
    it "returns proper json" do
      {
        d: BigDecimal.new("1234123412341234")
      }.to_json.should eq(%({"d":"1234123412341234"}))
    end
  end

end