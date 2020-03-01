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
      when /[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{6}Z/ # 2020-02-22T09:11:42.476953Z
        Time.parse(x.to_s, "%FT%X.%6NZ", Time::Location::UTC)
      when /[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\+[0-9]{2}:[0-9]{2}/ # 2020-02-24T11:05:28+07:00
        Time.parse!(x.to_s, "%FT%X%z")
      when /[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z/ # 2020-02-24T11:05:28Z
        Time.parse(x.to_s, "%FT%XZ", Time::Location::UTC)
      when /[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}Z/ # 2020-02-11T17:54:49.000Z
        Time.parse(x.to_s, "%FT%X.%NZ", Time::Location::UTC)
      else
        raise Time::Format::Error.new("Bad format for Time: #{time}")
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
