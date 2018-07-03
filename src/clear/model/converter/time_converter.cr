require "pg"

class Clear::Model::Converter::TimeConverter
  def self.to_column(x) : Time?
    case x
    when Nil
      nil
    when Time
      x.to_local
    else
      Time.parse(x.to_s, "%F %X.%L").to_local
    end
  end

  def self.to_db(x : Time?)
    case x
    when Nil
      nil
    else
      x.to_utc.to_s(Clear::Expression::DATABASE_DATE_TIME_FORMAT)
    end
  end
end
