module Clear::SQL
  class Error < Exception; end

  class ExecutionError < Error; end

  class QueryBuildingError < Error; end
end
