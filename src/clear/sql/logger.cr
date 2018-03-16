require "colorize"
require "logger"
require "benchmark"

module Clear::SQL::Logger
  SQL_KEYWORDS = Set(String).new(%w(
    ADD ALL ALTER ANALYSE ANALYZE AND ANY ARRAY AS ASC ASYMMETRIC
    BEGIN BOTH CASE CAST CHECK COLLATE COLUMN COMMIT CONSTRAINT CREATE CROSS
    CURRENT_DATE CURRENT_ROLE CURRENT_TIME CURRENT_TIMESTAMP
    CURRENT_USER CURSOR DECLARE DEFAULT DELETE DEFERRABLE DESC
    DISTINCT DROP DO ELSE END EXCEPT EXISTS FALSE FETCH FULL FOR FOREIGN FROM GRANT
    GROUP HAVING IF IN INDEX INNER INSERT INITIALLY INTERSECT INTO JOIN LEADING
    LIMIT LEFT LOCALTIME LOCALTIMESTAMP NEW NOT NULL OFF OFFSET OLD ON ONLY OR
    ORDER OUTER PLACING PRIMARY REFERENCES RELEASE RETURNING RIGHT ROLLBACK
    SAVEPOINT SELECT SESSION_USER SET SOME SYMMETRIC TABLE THEN TO
    TRAILING TRUE UNION UNIQUE UPDATE USER USING VALUES WHEN WHERE
  ))

  def self.colorize_query(qry : String)
    o = qry.to_s.split(/([a-zA-Z0-9_]+)/).map do |word|
      if SQL_KEYWORDS.includes?(word.upcase)
        word.colorize.bold.blue.to_s
      elsif word =~ /\d+/
        word.colorize.red
      else
        word.colorize.white
      end
    end.join("")
    o.gsub(/(--.*)$/) { |x| x.colorize.dark_gray }
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
      (1_000*x).to_i.to_s + "ms"
    else
      (1_000_000*x).to_i.to_s + "µs"
    end
  end

  def log_query(sql, &block)
    time = Time.now.epoch_f
    yield
  ensure
    time = Time.now.epoch_f - time.not_nil!
    Clear.logger.debug(("[" + Clear::SQL::Logger.display_time(time).colorize.bold.white.to_s + "] #{SQL::Logger.colorize_query(sql)}"))
  end
end
