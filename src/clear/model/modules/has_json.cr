module Clear::Model::HasJson
  def to_json(full : Bool)
    to_h(full).to_json
  end

  def to_json(json, full = false)
    to_h(full).to_json(json)
  end
end
