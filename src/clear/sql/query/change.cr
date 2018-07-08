module Clear::SQL::Query::Change
  # This method is called everytime the request has been changed
  # By default, this do nothing and return `self`. However, it can be
  # reimplemented to change some behavior when the query is changed
  #
  # (eg. it is by `Clear::Model::Collection`, to discard cache over collection)
  def change! : self
    self
  end
end
