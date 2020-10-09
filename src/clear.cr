# # Welcome to Clear ORM !
#
# Clear ORM is currently in heavy development.
# The goal is to provide an advanced ORM for postgreSQL.
#
# Instead of working on adapter for differents database, I wanted to offer the
# maximum features for a specific platform.
#
# It's not every day we chose a database layout, and there's few reasons for you
# to change your database during the development cycle (at least, from SQL to SQL).
#
# Postgres offers a lot of features in a very performant engine, and seems suitable
# for large projects in Crystal.
#
# And here you have ! The ORM made for Postgres and Crystal, simple to use, full
# of ideas stolen to ActiveRecord and Sequel :-).
require "./clear/core"
require "./clear/extensions/**"
require "./clear/cli"
