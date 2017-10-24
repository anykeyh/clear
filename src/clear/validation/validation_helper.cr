module Clear::ValidationHelper
  macro _on_presence(field, &block)
    if persisted?
      if {{field.id}}_field.defined?
        {{yield}}
      end
    else
      {{yield}}
    end
  end

  macro validate_presence(field, message)
    x = {{field.id}}_field.value(nil)

    if  x.nil? || ( x.responds_to?(:empty?) && x.empty? )
      add_error({{message}}, {{field.stringify}})
    end
  end

  macro validate_format(field, regexp, message)
    _on_presence({{field}}) do
      x = {{field.id}}.as(String)
      unless x =~ {{regexp}}
        add_error({{message}}, {{field.stringify}})
      end
    end
  end

  macro validate_not_null(field, message)
    _on_presence({{field}}) do
      add_error({{message}}, {{field.stringify}}) if {{field}}.nil?
    end
  end

  macro validate_includes(field, array, message)
    _on_presence({{field}}) do
      add_error({{message}}, {{field.stringify}}) if {{array}}.include?({{field}})
    end
  end

  macro validate_greater_than(field, number, message)
    _on_presence({{field}}) do
      if {{field.id}} < number
        add_error({{message}}, {{field.stringify}})
      end
    end
  end

  macro validate_lesser_than(field, number, message)
    _on_presence({{field}}) do
      if {{field.id}} > number
        add_error({{message}}, {{field.stringify}})
      end
    end
  end
end
