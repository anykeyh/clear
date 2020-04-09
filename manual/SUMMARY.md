# Table of contents

* [Welcome to Clear](README.md)

## Introduction

* [Setup](introduction/installation.md)

## Model

* [Defining your model](model/column-types/README.md)
  * [Describing your columns](model/column-types/model-definition.md)
  * [Primary Keys](model/column-types/primary-keys.md)
  * [Converters](model/column-types/converters.md)
* [Associations](model/associations/README.md)
  * [belongs\_to](model/associations/belongs_to.md)
  * [has\_many](model/associations/has_many.md)
  * [has\_many through](model/associations/has_many-through.md)
  * [has\_one](model/associations/has_one.md)
* [Lifecycle](model/lifecycle/README.md)
  * [Persistence](model/lifecycle/persistence.md)
  * [Validations](model/lifecycle/validations.md)
  * [Triggers](model/lifecycle/callbacks.md)
* [Batchs operations](model/batchs-operations/README.md)
  * [Bulk update](model/batchs-operations/bulk-update.md)
  * [Bulk insert & delete](model/batchs-operations/bulk-insert.md)
* [Transactions & Save Points](model/transactions-and-save-points/README.md)
  * [Transaction & Savepoints](model/transactions-and-save-points/transaction.md)
  * [Connection pool](model/transactions-and-save-points/connection-pool.md)
* [Locks](model/locks.md)

## Querying

* [The collection object](querying/the-collection-object/README.md)
  * [Filter the query](querying/the-collection-object/filter-the-query-1/README.md)
    * [Filter the query – The Expression Engine](querying/the-collection-object/filter-the-query-1/filter-the-query.md)
    * [Find, First, Last, Offset, Limit](querying/the-collection-object/filter-the-query-1/find-first.md)
    * [Aggregation](querying/the-collection-object/filter-the-query-1/aggregation.md)
    * [Ordering & Group by](querying/the-collection-object/filter-the-query-1/ordering.md)
  * [Fetching the query](querying/the-collection-object/fetching-the-query/README.md)
    * [Each and Fetch](querying/the-collection-object/fetching-the-query/each-map-fetch.md)
    * [Cursored fetching](querying/the-collection-object/fetching-the-query/cursored-fetching.md)
    * [Model extra attributes](querying/the-collection-object/fetching-the-query/model-attributes.md)
  * [Joins](querying/the-collection-object/joins.md)
  * [Eager Loading](querying/the-collection-object/n+1-query-avoidance.md)
  * [Window and CTE](querying/the-collection-object/window-and-cte.md)
  * [Scopes](querying/the-collection-object/scopes.md)
* [Writing low-level SQL](querying/low-level-sql/README.md)
  * [Select Clause](querying/low-level-sql/select-clause.md)
  * [Insert Clause](querying/low-level-sql/insert-clause.md)
  * [Delete Clause](querying/low-level-sql/delete-clause.md)

## Migrations

* [Manage migrations](migrations/manage-migrations.md)
* [Call migration script](migrations/call-migration-script.md)
* [Migration CLI](migrations/migration-cli.md)

## Additional and advanced features

* [JSONB](additional-and-advanced-features/jsonb.md)
* [Symbol vs String](additional-and-advanced-features/symbol-vs-string.md)
* [Enums](additional-and-advanced-features/enums.md)
* [BCrypt](additional-and-advanced-features/bcrypt.md)
* [Full Text Search](additional-and-advanced-features/full-text-search.md)
* [Handling multi-connection](additional-and-advanced-features/handling-multi-connection.md)

## Other resources

* [API Documentation](https://anykeyh.github.io/clear/)
* [Inline documentation](https://anykeyh.github.io/clear/)
* [Github repository](https://github.com/anykeyh/clear)
* [Credits](https://github.com/anykeyh/clear/blob/master/CONTRIBUTORS.md)
* [Benchmark](other-resources/benchmark.md)

