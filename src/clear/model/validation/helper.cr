module Clear::Validation::Helper
  macro _on_presence(field, &block)
    if persisted?
      if {{field.id}}_column.defined?
        {{yield}}
      end
    else
      {{yield}}
    end
  end

  macro ensure_than(field, message, &block)
    o = {{field.id}}
    _on_presence({{field.id}}) do
      fn = Clear::Util.func(typeof(o), Object) {{block}}

      unless fn.call(o)
        add_error({{field.stringify}}, {{message}})
      end
    end
  end

  # macro validate_presence(field, message)
  #   x = {{field.id}}_column.value(nil)

  #   if  x.nil? || ( x.responds_to?(:empty?) && x.empty? )
  #     add_error({{field.stringify}}, {{message}})
  #   end
  # end

  # macro validate_format(field, regexp, message)
  #   _on_presence({{field}}) do
  #     x = {{field.id}}.as(String)
  #     unless x =~ {{regexp}}
  #       add_error({{field.stringify}}, {{message}})
  #     end
  #   end
  # end

  # macro validate_not_null(field, message)
  #   _on_presence({{field}}) do
  #     add_error({{field.stringify}}, {{message}}) if {{field}}.nil?
  #   end
  # end

  # macro validate_includes(field, array, message)
  #   _on_presence({{field}}) do
  #     add_error({{field.stringify}}, {{message}}) if {{array}}.include?({{field}})
  #   end
  # end

  # macro validate_greater_than(field, number, message)
  #   _on_presence({{field}}) do
  #     if {{field.id}} < number
  #       add_error({{field.stringify}}, {{message}})
  #     end
  #   end
  # end

  # macro validate_lesser_than(field, number, message)
  #   _on_presence({{field}}) do
  #     if {{field.id}} > number
  #       add_error({{field.stringify}}, {{message}})
  #     end
  #   end
  # end
end
