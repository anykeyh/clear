require "colorize"
require "log"
require "benchmark"

module Clear::SQL::Logger
  class_property colorize : Bool = STDOUT.tty? && STDERR.tty?

  private SQL_KEYWORDS = Set(String).new(%w(
    ADD ALL ALTER ANALYSE ANALYZE AND ANY ARRAY AS ASC ASYMMETRIC
    BEGIN BOTH BY CASE CAST CHECK COLLATE COLUMN COMMIT CONSTRAINT COUNT CREATE CROSS
    CURRENT_DATE CURRENT_ROLE CURRENT_TIME CURRENT_TIMESTAMP
    CURRENT_USER CURSOR DECLARE DEFAULT DELETE DEFERRABLE DESC
    DISTINCT DROP DO ELSE END EXCEPT EXISTS FALSE FETCH FULL FOR FOREIGN FROM GRANT
    GROUP HAVING IF IN INDEX INNER INSERT INITIALLY INTERSECT INTO JOIN LAGGING
    LEADING LIMIT LEFT LOCALTIME LOCALTIMESTAMP NATURAL NEW NOT NULL OFF OFFSET
    OLD ON ONLY OR ORDER OUTER PLACING PRIMARY REFERENCES RELEASE RETURNING
    RIGHT ROLLBACK SAVEPOINT SELECT SESSION_USER SET SOME SYMMETRIC
    TABLE THEN TO TRAILING TRIGGER TRUE UNION UNIQUE UPDATE USER USING VALUES
    WHEN WHERE WINDOW
  ))

  def self.colorize_query(qry : String)
    return qry unless @@colorize

    o = qry.to_s.split(/([a-zA-Z0-9_]+)/).join do |word|
      if SQL_KEYWORDS.includes?(word.upcase)
        word.colorize.bold.blue.to_s
      elsif word =~ /\d+/
        word.colorize.red
      else
        word.colorize.white
      end
    end
    o.gsub(/(--.*)$/, &.colorize.dark_gray)
  end

  def self.display_mn_sec(x : Float64) : String
    mn = x.to_i / 60
    sc = x.to_i % 60

    {mn > 9 ? mn : "0#{mn}", sc > 9 ? sc : "0#{sc}"}.join("mn") + "s"
  end

  def self.display_time(x : Float64) : String
    if (x > 60)
      display_mn_sec(x)
    elsif (x > 1)
      ("%.2f" % x) + "s"
    elsif (x > 0.001)
      (1_000 * x).to_i.to_s + "ms"
    else
      (1_000_000 * x).to_i.to_s + "µs"
    end
  end

  # Log a specific query, wait for it to return
  def log_query(sql : String, &block)
    start_time = Time.monotonic

    o = yield
    elapsed_time = Time.monotonic - start_time

    Log.debug {
      "[" + Clear::SQL::Logger.display_time(elapsed_time.to_f).colorize.bold.white.to_s + "] #{SQL::Logger.colorize_query(sql)}"
    }

    o
  rescue e
    raise Clear::SQL::Error.new(
      message: [e.message, "Error caught, last query was:", Clear::SQL::Logger.colorize_query(sql)].compact.join("\n"),
      cause: e
    )
  end
end
