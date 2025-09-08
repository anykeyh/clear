#!/bin/bash

DB_NAME=${DB_NAME:="clear_spec"}
DB_NAME_SECONDARY=${DB_NAME_SECONDARY:="clear_secondary_spec"}
DB_NAME_SYSTEM=${DB_NAME_SYSTEM:="postgres"}

DB_HOST=${DB_HOST:="localhost"}
DB_PORT=${DB_PORT:="5432"}
DB_USER=${DB_USER:="postgres"}
DB_PASSWORD=${DB_PASSWORD:="postgres"}


function exec_psql_sys() {
  psql postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME_SYSTEM 1>/dev/null
}

function exec_psql_sec() {
  psql postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME_SECONDARY 1>/dev/null
}


echo "DROP DATABASE IF EXISTS $DB_NAME;" | exec_psql_sys
echo "CREATE DATABASE $DB_NAME;" | exec_psql_sys
echo "DROP DATABASE IF EXISTS $DB_NAME_SECONDARY;" | exec_psql_sys
echo "CREATE DATABASE $DB_NAME_SECONDARY;" | exec_psql_sys
echo "CREATE TABLE models_post_stats (id serial PRIMARY KEY, post_id INTEGER);" | exec_psql_sec