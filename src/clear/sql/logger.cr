require "colorize"
require "logger"
require "benchmark"

module Clear::SQL::Logger
  macro included
    class_property logger : ::Logger = ::Logger.new(STDOUT)
    logger.level = ::Logger::DEBUG
  end

  SQL_KEYWORDS = %w(
    ALL ANALYSE ANALYZE AND ANY ARRAY AS ASC ASYMMETRIC
    BOTH CASE CAST CHECK COLLATE COLUMN CONSTRAINT CREATE
    CURRENT_DATE CURRENT_ROLE CURRENT_TIME CURRENT_TIMESTAMP
    CURRENT_USER DEFAULT DEFERRABLE DESC DISTINCT DO ELSE
    END EXCEPT FALSE FOR FOREIGN FROM GRANT GROUP HAVING IN INSERT
    INITIALLY INTERSECT INTO LEADING LIMIT LOCALTIME LOCALTIMESTAMP
    NEW NOT NULL OFF OFFSET OLD ON ONLY OR ORDER PLACING PRIMARY
    REFERENCES SELECT SESSION_USER SOME SYMMETRIC TABLE THEN TO
    TRAILING TRUE UNION UNIQUE USER USING WHEN WHERE
  )

  def self.colorize_query(qry : String)
    qry.to_s.split(/([a-zA-Z0-9_]+)/).map do |word|
      if SQL_KEYWORDS.includes?(word.upcase)
        word.colorize.bold.blue.to_s
      elsif word =~ /\d+/
        word.colorize.red
      else
        word.colorize.dark_gray
      end
    end.join("")
  end

  def self.display_mn_sec(x) : String
    mn = x.to_i / 60
    sc = x.to_i % 60

    [mn > 9 ? mn : "0#{mn}", sc > 9 ? sc : "0#{sc}"].join("mn") + "s"
  end

  def self.display_time(x) : String
    if (x > 60)
      display_mn_sec(x)
    elsif (x > 1)
      ("%.2f" % x) + "s"
    elsif (x > 0.001)
      (1000*x).to_i.to_s + "ms"
    else
      (1000000*x).to_i.to_s + "µs"
    end
  end

  def log_query(sql, &block)
    time = Time.now.epoch_f # TODO: Change to Time.monotonic
    yield
  ensure
    time = Time.now.epoch_f - time.not_nil!
    logger.debug(("[" + SQL::Logger.display_time(time).colorize.bold.white.to_s + "] #{SQL::Logger.colorize_query(sql)}"))
  end
end
