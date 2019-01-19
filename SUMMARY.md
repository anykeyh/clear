# Table of contents

* [Welcome to Clear](README.md)

## Introduction

* [Setup](introduction/installation.md)

## Model

* [Defining your model](model/column-types/README.md)
  * [The column feature](model/column-types/model-definition.md)
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
  * [Bulk insert](model/batchs-operations/bulk-insert.md)
* [Transactions & Save Points](model/transactions-and-save-points/README.md)
  * [Transaction & Savepoints](model/transactions-and-save-points/transaction.md)
  * [Connection pool](model/transactions-and-save-points/connection-pool.md)
* [Locks](model/locks.md)

## Querying

* [The collection object](querying-1/the-collection-object/README.md)
  * [Filter the query](querying-1/the-collection-object/filter-the-query-1/README.md)
    * [Filter the query – The Expression Engine](querying-1/the-collection-object/filter-the-query-1/filter-the-query.md)
    * [Find, First, Last, Offset, Limit](querying-1/the-collection-object/filter-the-query-1/find-first.md)
    * [Aggregation](querying-1/the-collection-object/filter-the-query-1/aggregation.md)
    * [Ordering & Group by](querying-1/the-collection-object/filter-the-query-1/ordering.md)
  * [Fetching the query](querying-1/the-collection-object/fetching-the-query/README.md)
    * [Each and Fetch](querying-1/the-collection-object/fetching-the-query/each-map-fetch.md)
    * [Cursored fetching](querying-1/the-collection-object/fetching-the-query/cursored-fetching.md)
    * [Model extra attributes](querying-1/the-collection-object/fetching-the-query/model-attributes.md)
  * [Joins](querying-1/the-collection-object/joins.md)
  * [Eager Loading – Resolving the N+1 query problem](querying-1/the-collection-object/n+1-query-avoidance.md)
  * [Window and CTE](querying-1/the-collection-object/window-and-cte.md)
  * [Scopes](querying-1/the-collection-object/scopes.md)
* [Low-level SQL](querying-1/low-level-sql/README.md)
  * [Select Clause](querying-1/low-level-sql/select-clause.md)
  * [Insert Clause](querying-1/low-level-sql/insert-clause.md)
  * [Delete Clause](querying-1/low-level-sql/delete-clause.md)

## Migrations

* [Manage migrations](migrations-1/manage-migrations.md)
* [Call migration script](migrations-1/call-migration-script.md)
* [Migration CLI](migrations-1/migration-cli.md)

## Additional and advanced features

* [Symbol vs String](additionals/symbol-vs-string.md)
* [Enums](additionals/enums.md)
* [BCrypt](additionals/bcrypt.md)
* [Full Text Search](additionals/full-text-search.md)
* [JSONB](additionals/jsonb.md)
* [Handling multi-connection](additionals/handling-multi-connection.md)

## Other resources

* [Inline documentation](https://anykeyh.github.io/clear/)
* [Github repository](https://github.com/anykeyh/clear)
* [Credits](https://github.com/anykeyh/clear/blob/master/CONTRIBUTORS.md)
* [Benchmark](other-resources/benchmark.md)

