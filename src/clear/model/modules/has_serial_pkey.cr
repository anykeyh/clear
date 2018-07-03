require "uuid"

module Clear::Model::HasSerialPkey
  # Helper for lazy developers, to add longint primary key.
  macro with_serial_pkey(name = "id", type = :bigserial)
    {% if type == :bigserial %}
      column {{name.id}} : UInt64, primary: true, presence: false
    {% elsif type == :serial %}
      column {{name.id}} : UInt32, primary: true, presence: false
    {% elsif type == :uuid %}
      column {{name.id}} : UUID, primary: true, presence: true

      before(:validate) do |m|
        m.{{name.id}} = UUID.random unless m.persisted?
      end
    {% else %}
      {% raise "with_serial_pkey: known type are :serial | :bigserial | :uuid" %}
    {% end %}
  end
end
