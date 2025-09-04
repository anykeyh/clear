module Clear::Validation::Helper
  macro on_presence(*fields, &block)
    if {{ fields.map { |x| "self.#{x.id}_column.defined?" }.join(" && ").id }}
      {{yield}}
    end
  end

  # Usage example:
  #
  # ```
  # ensure_than email, "must be an email" do |v|
  #   EmailRegexp.valid?(v)
  # end
  # ```
  macro ensure_than(field, message, &block)

    if {{field.id}}_column.defined?
      o = {{field.id}}

      fn = Clear::Util.lambda(typeof(o), Object) {{block}}

      unless fn.call(o)
        add_error({{field.stringify}}, {{message}})
      end
    end

  end
end
