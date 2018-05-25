module Clear::Model
  class Error < Exception; end

  class InvalidModelError < Error; end

  class ReadOnlyModelError < Error; end
end
