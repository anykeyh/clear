#!/bin/sh

echo "DROP DATABASE IF EXISTS clear_spec;" | psql -U postgres
echo "CREATE DATABASE clear_spec;" | psql -U postgres

CMD="sample/cli/cli.cr -- --verbose"

crystal $CMD migrate #Go to the version 3

crystal $CMD migration status # Version 1,2,3 loaded
crystal $CMD migration set 2 #Go to the version 2

crystal $CMD migration status # Version 1,2 loaded
crystal $CMD migration set 3 #Go back to 3

crystal $CMD migration status # Version 1,2,3 loaded
crystal $CMD migration down 2 #Down the migration 2

crystal $CMD migration status # Version 1,3 loaded

crystal $CMD migration set -1 #Down the migration 3?

crystal $CMD migration status # Version 1,2 loaded

crystal $CMD migrate #Go to the version 3

crystal $CMD migration status # Version 1,2,3 loaded
crystal $CMD rollback #Rollback to 2


crystal $CMD migration status # Version 1,2 loaded

crystal $CMD migration down 1 # Remove 1
crystal $CMD rollback # Remove 3

crystal $CMD migration status # Version 2 loaded
