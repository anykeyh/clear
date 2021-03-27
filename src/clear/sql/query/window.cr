module Clear::SQL::Query::Window
  alias WindowDeclaration = {String, String}

  # eq. WINDOW window_name AS ( window_definition )
  getter windows : Array(WindowDeclaration)

  def window(windows : NamedTuple)
    windows.each do |k, v|
      @windows << {k.to_s, v.to_s}
    end

    change!
  end

  def window(name, value)
    @windows << {name.to_s, value.to_s}

    change!
  end

  def clear_windows
    @windows.clear

    change!
  end

  def print_windows
    @windows.join do |name, value|
      {name.to_s, " AS ", value}.join
    end
  end
end
