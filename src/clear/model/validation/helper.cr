module Clear::Validation::Helper
  macro on_presence(field, &block)
    if persisted?
      if {{field.id}}_column.defined?
        {{yield}}
      end
    else
      {{yield}}
    end
  end

  # Usage example:
  #
  # ```crystal
  #  ensure_than email, "must be an email" do |v|
  #     EmailRegexp.valid?(v)
  #  end
  # ```
  macro ensure_than(field, message, &block)
    o = {{field.id}}
    on_presence({{field.id}}) do
      fn = Clear::Util.lambda(typeof(o), Object) {{block}}

      unless fn.call(o)
        add_error({{field.stringify}}, {{message}})
      end
    end
  end

end
