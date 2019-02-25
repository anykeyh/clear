require "uuid"

module Clear::Model::HasSerialPkey
  PKEY_TYPE = {} of Nil => Nil

  @[Deprecated]
  macro with_serial_pkey(name = "id", type = :bigserial)
    {% puts "[DEPRECATION WARNING] Please use `primary_key` instead. In future version of Clear, `with_serial_pkey` will be removed (declared in `#{@type}`).".id %}
    primary_key({{name}}, {{type}})
  end

  # Macro used to define serializable primary keys.
  # Currently support `bigserial`, `serial` and `uuid`.
  #
  # For `bigserial` and `serial`, let to PostgreSQL the handling of sequence numbers.
  # For `uuid`, will generate a new `UUID` number on creation.
  macro primary_key(name = "id", type = :bigserial)
    {% type = "#{type.id}" %}
    {% cb = PKEY_TYPE[type] %}
    {% if cb %}
      {{cb.gsub(/__name__/, name).id}}
    {% else %}
      { raise "Cannot define primary key of type #{type}. Candidates are: #{PKEY_TYPE.keys.join(", ")}" %}
    {% end %}
  end

  # Add a hook for the `primary_key`
  # In the hook, __name__ will be replaced by the column name required by calling primary_key
  #
  # ## Example
  #
  # ```
  #   Clear::Model::HasSerialPkey.add_pkey_type("awesomepkeysystem") do
  #     column __name__ : AwesomePkey, primary: true, presence: false
  #
  #     before_validate do
  #        #...
  #     end
  #   end
  # ```
  macro add_pkey_type(type, &block)
    {% PKEY_TYPE[type] = "#{block.body}" %}
  end

  add_pkey_type "bigserial" do
    column __name__ : Int64, primary: true, presence: false
  end

  add_pkey_type "serial" do
    column __name__ : Int32, primary: true, presence: false
  end

  add_pkey_type "text" do
    column __name__ : String, primary: true, presence: true
  end

  add_pkey_type "int" do
    column __name__ : Int32, primary: true, presence: true
  end

  add_pkey_type "bigint" do
    column __name__ : Int64, primary: true, presence: true
  end

end
