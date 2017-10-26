#!/bin/sh

USER = postgres
DB = "clear_spec"

psql -U $USER -C "DROP IF EXISTS DATABASE $DB; CREATE DATABASE $DB;"
psql -U $USER -d $DB "CREATE TABLE users(id integer PRIMARY, first_name );"
