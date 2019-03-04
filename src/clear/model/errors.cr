module Clear::Model
  class Error < Exception; end

  class InvalidError < Error
    getter model : Clear::Model

    def initialize(@model : Clear::Model)
      super("The model `#{@model.class}` is invalid:\n#{model.print_errors}")
    end
  end

  class ReadOnlyError < Error
    getter model : Clear::Model

    def initialize(@model : Clear::Model)
      super("The model `#{@model.class}` is read-only")
    end
  end
end
