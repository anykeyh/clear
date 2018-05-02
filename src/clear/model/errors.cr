module Clear::Model
  class Error < Exception; end

  class InvalidModelError < Error; end

  class ReadOnlyModel < Error; end
end
