module Clear::SQL
  abstract struct Fragment
    abstract def to_sql
  end
end
