require "base64"

# Extension of some objects outside of Clear ("Monkey Patching")

struct Char
  def to_json(json)
    json.string("#{self}")
  end
end

struct PG::Geo::Box
  # :nodoc:
  def to_json(json)
    json.object do
      json.field("x1") { json.number x1 }
      json.field("x2") { json.number x2 }
      json.field("y1") { json.number y1 }
      json.field("y2") { json.number y2 }
    end
  end
end

struct PG::Geo::LineSegment
  def to_json(json)
    json.object do
      json.field("x1") { json.number x1 }
      json.field("x2") { json.number x2 }
      json.field("y1") { json.number y1 }
      json.field("y2") { json.number y2 }
    end
  end
end

struct PG::Geo::Point
  def to_json(json)
    json.object do
      json.field("x") { json.number x }
      json.field("y") { json.number y }
    end
  end
end

struct PG::Geo::Line
  def to_json(json)
    json.object do
      json.field("a") { json.number a }
      json.field("b") { json.number b }
      json.field("c") { json.number c }
    end
  end
end

struct PG::Geo::Circle
  def to_json(json)
    json.object do
      json.field("x") { json.number x }
      json.field("y") { json.number y }
      json.field("radius") { json.number radius }
    end
  end
end

struct PG::Geo::Path
  def to_json(json)
    json.object do
      json.field("points") do
        json.array do
          points.each do
            points.to_json(json)
          end
        end
      end
      json.field("closed") { json.bool(closed?) }
    end
  end
end

struct PG::Geo::Polygon
  def to_json(json)
    json.object do
      json.array do
        points.each do
          points.to_json(json)
        end
      end
    end
  end
end

struct Slice(T)
  def to_json(json)
    s = String::Builder.new
    to_s(s)
    json.string(Base64.strict_encode(s.to_s))
  end
end

struct PG::Numeric
  def to_json(json)
    s = String::Builder.new
    to_s(s)
    json.string(s.to_s)
  end
end
