module Clear::SQL
  class Error < Exception; end

  class ExecutionError < Error; end

  class QueryBuildingError < Error; end

  class OperationNotPermittedError < Error; end

  class RecordNotFoundError < Error; end

  # Rollback the transaction or the last savepoint.
  class RollbackError < Error
    getter savepoint_id : String?

    def initialize(@savepoint_id = nil)
    end
  end

  # Like rollback, but used with savepoint, it will revert completely the transaction
  class CancelTransactionError < Error; end
end
