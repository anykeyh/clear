require "./base"

class Clear::Model::Converter::TimeConverter
  def self.to_column(x) : Time?
    case x
    when Nil
      nil
    when Time
      x.to_local
    else
      time = x.to_s
      case time
      when /[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]+/ # 2020-02-22 09:11:42.476953
        Time.parse_local(x.to_s, "%F %X.%L")
      else
        Time::Format::RFC_3339.parse(time)
      end
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

Clear::Model::Converter.add_converter("Time", Clear::Model::Converter::TimeConverter)
