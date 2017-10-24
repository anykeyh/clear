require "pg"

class Clear::Model::Converter::TimeConverter
  def self.to_field(x : ::Clear::SQL::Any) : Time?
    case x
    when Nil
      nil
    else
      Time.parse(x.to_s, "%F %X")
    end
  end

  def self.to_db(x : Time?)
    case x
    when Nil
      nil
    else
      x.to_s(Clear::Expression::DATABASE_DATE_TIME_FORMAT)
    end
  end
end
