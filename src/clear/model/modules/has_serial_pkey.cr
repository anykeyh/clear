module Clear::Model::HasSerialPkey
  # Helper for lazy developers, to add longint primary key.
  macro with_serial_pkey(name = "id")
    column {{name.id}} : UInt64, primary: true, presence: false
  end
end
