module Clear::SQL::Query::Change
  # Call back called when the query is changed
  # Just here for being reimplemented
  def change! : self
    self
  end
end
