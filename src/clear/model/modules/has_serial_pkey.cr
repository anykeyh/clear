require "uuid"

module Clear::Model::HasSerialPkey
  # Macro used to define serializable primary keys.
  # Currently support `bigserial`, `serial` and `uuid`.
  #
  # For `bigserial` and `serial`, let to PostgreSQL the handling of sequence numbers.
  # For `uuid`, will generate a new `UUID` number on creation.
  macro with_serial_pkey(name = "id", type = :bigserial)

    {% if type == :bigserial %}
      column {{name.id}} : Int64, primary: true, presence: false
    {% elsif type == :serial %}
      column {{name.id}} : Int32, primary: true, presence: false
    {% elsif type == :uuid %}
      column {{name.id}} : UUID, primary: true, presence: true

      before(:validate) do |m|
        m.as(self).{{name.id}} = UUID.random unless m.persisted?
      end
    {% else %}
      {% raise "with_serial_pkey: known type are :serial | :bigserial | :uuid" %}
    {% end %}
  end
end
