module Clear::SQL
  class Error < Exception; end

  class ExecutionError < Error; end

  class QueryBuildingError < Error; end

  class OperationNotPermittedError < Error; end

  class RecordNotFoundError < Error; end

  # Rollback the transaction or the last savepoint.
  class RollbackError < Error; end

  # Like rollback, but used into savepoint, it will revert completely the transaction
  class CancelTransactionError < Error; end
end
