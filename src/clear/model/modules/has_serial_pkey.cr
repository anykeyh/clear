module Clear::Model::HasSerialPkey
  macro with_serial_pkey(x = "id")
    column {{x.id}} : UInt64, primary: true, presence: false
  end
end
